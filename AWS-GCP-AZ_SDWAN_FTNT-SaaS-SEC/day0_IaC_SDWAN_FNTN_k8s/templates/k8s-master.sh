#!/bin/bash
# -------------------------------------------------------------------------------------------------------------
# User-data script to configure a K8S node master and populate parameters to AWS SSM to workes 
#
# jvigueras@fortinet.com
# -------------------------------------------------------------------------------------------------------------

#--------------------------------------------------------------------------------------------------------------
# Install K8S (master node)
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

# Initialize the Kubernetes cluster
kubeadm init \
    --pod-network-cidr=192.168.0.0/16 \
    --apiserver-cert-extra-sans=127.0.0.1,${cert_extra_sans} \
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
# Python script to export bootstrap token and created cicd service account to AWS SSM 
#--------------------------------------------------------------------------------------------------------------
# Install python dependencies
apt-get install -y python3-pip
pip3 install boto3 kubernetes

# Export the token and server certificate to AWS Parameter Store using Python
cat << EOF > export-cluster-info.py
${script}
EOF

# Run script
python3 export-cluster-info.py

#--------------------------------------------------------------------------------------------------------------
# Install FortiCNP agent
#--------------------------------------------------------------------------------------------------------------
wget https://forticwp-kubernetes-agent.s3.amazonaws.com/linux/fcli -O /tmp/fcli
chmod +x /tmp/fcli
cat << EOF > /home/ubuntu/join_forticnp.sh
/tmp/fcli deploy kubernetes --token ${forticnp_token} --region eu
EOF
/tmp/fcli deploy kubernetes --token ${forticnp_token} --region eu