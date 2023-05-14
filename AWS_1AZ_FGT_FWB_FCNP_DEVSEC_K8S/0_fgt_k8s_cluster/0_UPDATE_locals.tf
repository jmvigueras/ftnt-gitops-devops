locals {
  #-----------------------------------------------------------------------------------------------------
  # General variables
  #-----------------------------------------------------------------------------------------------------
  prefix = "fgt-k8s-cicd"
  region = {
    id  = "eu-west-1"
    az1 = "eu-west-1a"
    az2 = "eu-west-1a" // same AZ id as AZ1 for a single AZ deployment
  }
  #-----------------------------------------------------------------------------------------------------
  # K8S Cluster
  #-----------------------------------------------------------------------------------------------------
  param_path    = "/${local.prefix}"
  worker_number = 1

  node_master_cidrhost = 10 //Network IP address for master node
  node_instance_type   = "t3.2xlarge"
  disk_size            = 30

  api_port = 6443

  #-----------------------------------------------------------------------------------------------------
  # FGT
  #-----------------------------------------------------------------------------------------------------
  admin_port = "8443"
  admin_cidr = "${chomp(data.http.my-public-ip.body)}/32" // must be different from 0.0.0.0/0

  fgt_instance_type = "c6i.large"
  fgt_build         = "build1396"
  license_type      = "payg"

  fgt_vpc_cidr = "172.20.0.0/24"
}