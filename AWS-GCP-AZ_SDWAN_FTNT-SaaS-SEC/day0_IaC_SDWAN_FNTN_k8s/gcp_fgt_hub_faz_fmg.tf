
#------------------------------------------------------------------------------------------------------------
# Create VPCs and subnets Fortigate
# - VPC for MGMT and HA interface
# - VPC for Public interface
# - VPC for Private interface  
#------------------------------------------------------------------------------------------------------------
module "fgt_hub_vpc" {
  source = "git::github.com/jmvigueras/modules//gcp/vpc-fgt"

  region = local.gcp_region
  prefix = local.prefix

  vpc-sec_cidr = local.hub_vpc_cidr
}
#------------------------------------------------------------------------------------------------------------
# Create FGT cluster config
#------------------------------------------------------------------------------------------------------------
module "fgt_hub_config" {
  source = "git::github.com/jmvigueras/modules//gcp/fgt-config"

  admin_cidr     = local.admin_cidr
  admin_port     = local.admin_port
  rsa-public-key = trimspace(tls_private_key.ssh.public_key_openssh)

  subnet_cidrs       = module.fgt_hub_vpc.subnet_cidrs
  fgt-active-ni_ips  = module.fgt_hub_vpc.fgt-active-ni_ips
  fgt-passive-ni_ips = module.fgt_hub_vpc.fgt-passive-ni_ips

  config_fgcp = true
  config_hub  = true
  config_fmg  = true
  config_faz  = true

  hub    = local.hub
  fmg_ip = module.fgt_hub_vpc.fmg_ni_ips["private"]
  faz_ip = module.fgt_hub_vpc.faz_ni_ips["private"]

  cluster_pips = ["${local.prefix}-active-public-ip"]
  route_tables = google_compute_route.private_route_to_fgt_rfc1918.*.name

  vpc-spoke_cidr = [module.fgt_hub_vpc.subnet_cidrs["bastion"]]
}
#------------------------------------------------------------------------------------------------------------
# Create FGT cluster instances
#------------------------------------------------------------------------------------------------------------
module "fgt_hub" {
  source = "git::github.com/jmvigueras/modules//gcp/fgt-ha"

  prefix = local.prefix
  region = local.gcp_region
  zone1  = local.gcp_zone1
  zone2  = local.gcp_zone2

  machine        = local.gcp_faz-fmg_machine
  rsa-public-key = trimspace(tls_private_key.ssh.public_key_openssh)
  gcp-user_name  = split("@", data.google_client_openid_userinfo.me.email)[0]
  license_type   = local.gcp_fgt_license_type

  subnet_names       = module.fgt_hub_vpc.subnet_names
  fgt-active-ni_ips  = module.fgt_hub_vpc.fgt-active-ni_ips
  fgt-passive-ni_ips = module.fgt_hub_vpc.fgt-passive-ni_ips

  fgt_config_1 = module.fgt_hub_config.fgt_config_1
  fgt_config_2 = module.fgt_hub_config.fgt_config_2

  fgt_passive = false
}
#------------------------------------------------------------------------------------------------------------
# Create Bastion VPC private routes
#------------------------------------------------------------------------------------------------------------
resource "google_compute_route" "private_route_to_fgt_rfc1918" {
  depends_on  = [module.fgt_hub_vpc]
  count       = length(local.private_route_cidrs_rfc1918)
  name        = "${local.prefix}-rfc1918-to-fgt-${count.index + 1}"
  dest_range  = local.private_route_cidrs_rfc1918[count.index]
  network     = module.fgt_hub_vpc.vpc_ids["private"]
  next_hop_ip = module.fgt_hub_vpc.fgt-active-ni_ips["private"]
  priority    = 100
}
#------------------------------------------------------------------------------------------------------------
# Create FAZ instance
#------------------------------------------------------------------------------------------------------------
module "faz" {
  source = "git::github.com/jmvigueras/modules//gcp/faz"

  prefix  = local.prefix
  region  = local.gcp_region
  zone    = local.gcp_zone1
  machine = local.gcp_faz-fmg_machine

  rsa-public-key = trimspace(tls_private_key.ssh.public_key_openssh)
  gcp-user_name  = split("@", data.google_client_openid_userinfo.me.email)[0]

  subnet_names = {
    public  = module.fgt_hub_vpc.subnet_names["public"]
    private = module.fgt_hub_vpc.subnet_names["bastion"]
  }
  subnet_cidrs = {
    public  = module.fgt_hub_vpc.subnet_cidrs["public"]
    private = module.fgt_hub_vpc.subnet_cidrs["bastion"]
  }
  faz_ni_ips = module.fgt_hub_vpc.faz_ni_ips

  license_file = local.faz_license_file
}
#------------------------------------------------------------------------------------------------------------
# Create FMG instance
#------------------------------------------------------------------------------------------------------------
module "fmg" {
  source = "git::github.com/jmvigueras/modules//gcp/fmg"

  prefix  = local.prefix
  region  = local.gcp_region
  zone    = local.gcp_zone1
  machine = local.gcp_faz-fmg_machine

  rsa-public-key = trimspace(tls_private_key.ssh.public_key_openssh)
  gcp-user_name  = split("@", data.google_client_openid_userinfo.me.email)[0]

  subnet_names = {
    public  = module.fgt_hub_vpc.subnet_names["public"]
    private = module.fgt_hub_vpc.subnet_names["bastion"]
  }
  subnet_cidrs = {
    public  = module.fgt_hub_vpc.subnet_cidrs["public"]
    private = module.fgt_hub_vpc.subnet_cidrs["bastion"]
  }
  fmg_ni_ips = module.fgt_hub_vpc.fmg_ni_ips

  license_file = local.fmg_license_file
}