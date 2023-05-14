#!/bin/bash
# -------------------------------------------------------------------------------------------------------------
# User-data script to configure a K8S node workder and get parameters from AWS SSM to join a cluster
#
# jvigueras@fortinet.com
# -------------------------------------------------------------------------------------------------------------

#--------------------------------------------------------------------------------------------------------------
# Install K8S (worker node)
#--------------------------------------------------------------------------------------------------------------
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add
apt-add-repository -y "deb http://apt.kubernetes.io/ kubernetes-xenial main"
apt update -y

export K8SVERSION=${k8s_version}

apt install -y watch ipset tcpdump
apt install -y kubeadm=$${K8SVERSION} kubelet=$${K8SVERSION} kubectl=$${K8SVERSION}
          
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
${script}
EOF

# Populate data form parameter store
python3 join-cluster.py

# Join cluster command
kubeadm join $(cat /tmp/master) --token $(cat /tmp/token) --discovery-token-ca-cert-hash sha256:$(openssl x509 -pubkey -in /tmp/cert.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //')
