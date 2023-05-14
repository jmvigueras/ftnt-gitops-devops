locals {
  #-----------------------------------------------------------------------------------------------------
  # General variables AWS
  #-----------------------------------------------------------------------------------------------------
  prefix = "gitops-ftnt"
  region = {
    id  = "eu-west-1"
    az1 = "eu-west-1a"
    az2 = "eu-west-1c"
  }

  #-----------------------------------------------------------------------------------------------------
  # General variables GCP
  #-----------------------------------------------------------------------------------------------------
  gcp_region = "europe-west2"
  gcp_zone1  = "europe-west2-a"
  gcp_zone2  = "europe-west2-a"

  gcp_fgt_license_type = "payg"
  gcp_faz-fmg_machine  = "n1-standard-4"
  faz_license_file     = "./licenses/licenseFAZ.lic"
  fmg_license_file     = "./licenses/licenseFMG.lic"

  gcp_fgt_machine = "n1-standard-4"

  private_route_cidrs_rfc1918 = ["172.16.0.0/12", "10.0.0.0/8", "192.168.0.0/16"]

  #-----------------------------------------------------------------------------------------------------
  # General variables AZURE
  #-----------------------------------------------------------------------------------------------------
  resource_group_name      = null // a new resource group will be created if null
  storage-account_endpoint = null // a new resource group will be created if null
  location                 = "francecentral"

  tags = {
    Deploy  = "${local.prefix}-deployment"
    Project = "terraform-fortinet"
  }

  #-----------------------------------------------------------------------------------------------------
  # FGT SDWAN SITE (AZURE)
  #-----------------------------------------------------------------------------------------------------
  admin_username = "azureadmin"
  admin_password = "Terraform123#"

  az_license_type  = "payg"
  az_fgt_size      = "Standard_F4"
  az_fgt_version   = "latest"
  az_fgt_vnet_cidr = "192.168.100.0/23"

  spoke = {
    id      = "spoke-1"
    cidr    = local.az_fgt_vnet_cidr
    bgp_asn = local.hub["bgp-asn_spoke"]
  }

  #-----------------------------------------------------------------------------------------------------
  # K8S Cluster (AWS)
  #-----------------------------------------------------------------------------------------------------
  param_path = "/${local.prefix}"

  worker_number        = 1
  k8s_version          = "1.24.10-00"
  node_master_cidrhost = 10 //Network IP address for master node
  node_instance_type   = "t3.2xlarge"
  disk_size            = 30

  api_port = 6443

  #-----------------------------------------------------------------------------------------------------
  # FGT ONRAMP (AWS)
  #-----------------------------------------------------------------------------------------------------
  admin_port = "8443"
  admin_cidr = "${chomp(data.http.my-public-ip.response_body)}/32"

  aws_instance_type = "c6i.large"
  aws_fgt_build     = "build1396"
  aws_license_type  = "payg"

  fgt_vpc_cidr = "172.20.0.0/24"

  onramp = {
    id      = "onramp"
    cidr    = local.fgt_vpc_cidr
    bgp-asn = local.hub["bgp-asn_spoke"]
  }
  hubs = [{
    id                = local.hub["id"]
    bgp_asn           = local.hub["bgp-asn_hub"]
    external_ip       = module.fgt_hub.fgt_active_eip_public[0]
    hub_ip            = cidrhost(local.hub["vpn_cidr"], 1)
    site_ip           = ""
    hck_ip            = cidrhost(local.hub["vpn_cidr"], 1)
    vpn_psk           = module.fgt_hub_config.vpn_psk
    cidr              = local.hub["cidr"]
    ike_version       = local.hub["ike-version"]
    network_id        = local.hub["network_id"]
    dpd_retryinterval = local.hub["dpd-retryinterval"]
    sdwan_port        = "public"
  }]

  #-----------------------------------------------------------------------------------------------------
  # FGT HUB (GCP)
  #-----------------------------------------------------------------------------------------------------
  hub_vpc_cidr = "192.168.0.0/23"

  hub = {
    id                = "HUB"
    bgp-asn_hub       = "65000"
    bgp-asn_spoke     = "65000"
    vpn_cidr          = "10.10.10.0/24"
    vpn_psk           = "secret-key-123"
    cidr              = local.hub_vpc_cidr
    ike-version       = "2"
    network_id        = "1"
    dpd-retryinterval = "5"
    mode-cfg          = true
  }

  #-----------------------------------------------------------------------------------------------------
  # VPC Nodes and TGW (AWS)
  #-----------------------------------------------------------------------------------------------------
  tgw_bgp-asn     = "65515"
  tgw_cidr        = ["172.20.10.0/24"]
  tgw_inside_cidr = ["169.254.100.0/29", "169.254.101.0/29"]

  nodes_vpc_cidr    = "172.20.20.0/24"
  nodes_subnet_id   = module.nodes_vpc.subnet_az1_ids["vm"]
  nodes_subnet_cidr = module.nodes_vpc.subnet_az1_cidrs["vm"]
  nodes_sg_id       = module.nodes_vpc.nsg_ids["vm"]

  #---------------------------------------------------------------------
  # Github repo variables
  #---------------------------------------------------------------------
  github_site = "secdayforti"
}