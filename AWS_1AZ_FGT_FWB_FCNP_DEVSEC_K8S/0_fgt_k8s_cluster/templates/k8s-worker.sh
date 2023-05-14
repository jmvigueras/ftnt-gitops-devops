#!/bin/bash
#--------------------------------------------------------------------------------------------------------------
# Install K8S (worker node)
#--------------------------------------------------------------------------------------------------------------
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add
apt-add-repository "deb http://apt.kubernetes.io/ kubernetes-xenial main"
apt update -y

apt install -y watch ipset tcpdump
apt install -y kubeadm kubelet kubectl
          
cat <<EOF | tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

# Setup required sysctl params, these persist across reboots.
cat <<EOF | tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

# Apply sysctl params without reboot
sysctl --system

# Install containerd
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get install -y containerd.io

# Configure containerd
mkdir -p /etc/containerd
containerd config default | tee /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml

# Restart containerd
systemctl restart containerd

swapoff -a
kubeadm config images pull

#--------------------------------------------------------------------------------------------------------------
# Python script to retreive parameters from AWS SMS
#--------------------------------------------------------------------------------------------------------------
# Install dependencies
apt-get install -y python3-pip openssl
pip3 install boto3

# Python script to retreive parameters from AWS SMS
cat << EOF > join-cluster.py
import base64
import boto3
from botocore.config import Config
import os
import time

# AWS details to start boto3 client
my_config = Config(
    region_name = '${region}',
    signature_version = 'v4',
    retries = {
        'max_attempts': 10,
        'mode': 'standard'
    }
)
# Initialize the AWS SDK boto3 client
ssm = boto3.client("ssm", config=my_config)

# Retrieve master host variable from Parameter Store
master_host_param = ssm.get_parameter(Name="${param_path}/master_private_host")
# Write value to file
with open("/tmp/master", "w") as f:
    f.write(master_host_param['Parameter']['Value'])

# Loop until parameters token and cert won't be "default"
while True:
    token_param = ssm.get_parameter(Name="${param_path}/master_token", WithDecryption=True)
    # Check if the parameters are different from "default"
    if token_param['Parameter']['Value'] != "default":
        break
    # Wait for 10 seconds before checking again
    time.sleep(10)

# Write value to file
token_param = ssm.get_parameter(Name="${param_path}/master_token", WithDecryption=True)
with open("/tmp/token", "w") as f:
    f.write(token_param['Parameter']['Value'])

# Write value to file
cert_param = ssm.get_parameter(Name="${param_path}/master_ca_cert", WithDecryption=True)
cert_param_decode = base64.b64decode(cert_param['Parameter']['Value']).decode()
with open("/tmp/cert.crt", "w") as f:
    f.write(cert_param_decode)

EOF

# Populate data form parameter store
python3 join-cluster.py

# Join cluster command
kubeadm join $(cat /tmp/master) --token $(cat /tmp/token) --discovery-token-ca-cert-hash sha256:$(openssl x509 -pubkey -in /tmp/cert.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //')




