#!/bin/bash
#--------------------------------------------------------------------------------------------------------------
# Install K8S (master node)
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

# Initialize the Kubernetes cluster
kubeadm init \
    --pod-network-cidr=192.168.0.0/16 \
    --apiserver-cert-extra-sans=127.0.0.1,${master_public_ip} \
#     --skip-phases=addon/kube-proxy

# Export KUBECONFIG for ubuntu user
mkdir -p /home/ubuntu/.kube
cp -i /etc/kubernetes/admin.conf /home/ubuntu/.kube/config
chown ubuntu /home/ubuntu/.kube/config

# Export KUBECONFIG for root user
export KUBECONFIG="/etc/kubernetes/admin.conf"

# Install Calico
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.24.5/manifests/tigera-operator.yaml
curl https://raw.githubusercontent.com/projectcalico/calico/v3.24.5/manifests/custom-resources.yaml -O
sed -i 's/encapsulation: VXLANCrossSubnet/encapsulation: VXLAN/g' custom-resources.yaml
kubectl apply -f ./custom-resources.yaml

#--------------------------------------------------------------------------------------------------------------
# Create a service account and secret with a permanent cluster token
#--------------------------------------------------------------------------------------------------------------
kubectl create sa cicd-access -n default

# Create non expiring SA token
cat << EOF > new-sa.yaml
apiVersion: v1
kind: Secret
type: kubernetes.io/service-account-token
metadata:
  name: cicd-access
  annotations:
    kubernetes.io/service-account.name: cicd-access
EOF
kubectl apply -f new-sa.yaml

# Create a ClusterRoleBinding for the service account
kubectl create clusterrolebinding cicd-access --clusterrole cluster-admin --serviceaccount default:cicd-access

#--------------------------------------------------------------------------------------------------------------
# Python script to export bootstrap token to AWS SSM
#--------------------------------------------------------------------------------------------------------------
# Install python dependencies
apt-get install -y python3-pip
pip3 install boto3 kubernetes

# Export the token and server certificate to AWS Parameter Store using Python
cat << EOF > export-cluster-info.py
import base64
import boto3
import kubernetes
from kubernetes import client, config
from botocore.config import Config

# Load the Kubernetes configuration
config.load_kube_config()

# Create a Kubernetes client
kube_client = client.CoreV1Api()

# Get the token for the specified service account
cicd_token = kube_client.read_namespaced_secret(name="cicd-access", namespace="default").data["token"]

# Get the server certificate
cicd_cert = kube_client.read_namespaced_secret(name="cicd-access", namespace="default").data["ca.crt"]

# List all secrets in the namespace that have type kubernetes.io/service-account-token and get token secret
master_tokens = kube_client.list_namespaced_secret("kube-system", field_selector='type=bootstrap.kubernetes.io/token').items
master_token_secret = base64.b64decode(master_tokens[0].data["token-secret"]).decode()
master_token_id = base64.b64decode(master_tokens[0].data["token-id"]).decode()
master_token = master_token_id + "." + master_token_secret

# AWS boto3 client variables
my_config = Config(
    region_name = '${region}',
    signature_version = 'v4',
    retries = {
        'max_attempts': 10,
        'mode': 'standard'
    }
)

# Initialize the AWS SDK
ssm = boto3.client("ssm", config=my_config)

# Export the token and certificate to AWS Parameter Store
ssm.put_parameter(
    Name="${param_path}/cicd-access_token",
    Value=base64.b64decode(cicd_token).decode(),
    Type="SecureString",
    Overwrite=True
)
ssm.put_parameter(
    Name="${param_path}/master_ca_cert",
    Value=cicd_cert,
    Type="SecureString",
    Overwrite=True
)
ssm.put_parameter(
    Name="${param_path}/master_token",
    Value=master_token,
    Type="SecureString",
    Overwrite=True
)
EOF

# Run script
python3 export-cluster-info.py
