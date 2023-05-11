#------------------------------------------------------------------------------
# Create FGT cluster onramp
# - Create FGT onramp config (FGCP Active-Passive)
# - Create FGT instance
# - Create FGT VPC, subnets, NI and SG
#------------------------------------------------------------------------------
# Create FGT config
module "fgt_config" {
  source = "git::github.com/jmvigueras/modules//aws/fgt-config"

  admin_cidr     = local.admin_cidr
  admin_port     = local.admin_port
  rsa-public-key = trimspace(tls_private_key.ssh.public_key_openssh)
  api_key        = trimspace(random_string.api_key.result)

  subnet_active_cidrs  = module.fgt_vpc.subnet_az1_cidrs
  subnet_passive_cidrs = module.fgt_vpc.subnet_az1_cidrs
  fgt-active-ni_ips    = module.fgt_vpc.fgt-active-ni_ips
  fgt-passive-ni_ips   = module.fgt_vpc.fgt-passive-ni_ips

  fgt_active_extra-config  = data.template_file.fgt_active_extra-config_api.rendered
  fgt_passive_extra-config = data.template_file.fgt_passive_extra-config_api.rendered

  config_fgcp  = true
  config_spoke = true
  config_fmg   = true
  config_faz   = true

  fmg_ip = module.fmg.ni_ips["private"]
  faz_ip = module.faz.ni_ips["private"]
  hubs   = local.hubs
  spoke  = local.onramp

  vpc-spoke_cidr = [local.nodes_vpc_cidr, module.fgt_vpc.subnet_az1_cidrs["bastion"]]
}
# Create data template extra-config fgt
data "template_file" "fgt_active_extra-config_api" {
  template = file("./templates/fgt_extra-config.tpl")
  vars = {
    external_ip   = module.fgt_vpc.fgt-active-ni_ips["public"]
    mapped_ip     = cidrhost(local.nodes_subnet_cidr, local.node_master_cidrhost)
    external_port = local.api_port
    mapped_port   = local.api_port
    public_port   = "port2"
    private_port  = "port3"
    suffix        = local.api_port
  }
}
data "template_file" "fgt_passive_extra-config_api" {
  template = file("./templates/fgt_extra-config.tpl")
  vars = {
    external_ip   = module.fgt_vpc.fgt-passive-ni_ips["public"]
    mapped_ip     = cidrhost(local.nodes_subnet_cidr, local.node_master_cidrhost)
    external_port = local.api_port
    mapped_port   = local.api_port
    public_port   = "port2"
    private_port  = "port3"
    suffix        = local.api_port
  }
}
# Create FGT
module "fgt" {
  source = "git::github.com/jmvigueras/modules//aws/fgt-ha"

  prefix        = "${local.prefix}-onramp"
  region        = local.region
  instance_type = local.fgt_instance_type
  keypair       = aws_key_pair.keypair.key_name

  license_type = local.fgt_license_type
  fgt_build    = local.fgt_build

  fgt-active-ni_ids  = module.fgt_vpc.fgt-active-ni_ids
  fgt-passive-ni_ids = module.fgt_vpc.fgt-passive-ni_ids
  fgt_config_1       = module.fgt_config.fgt_config_1
  fgt_config_2       = module.fgt_config.fgt_config_2

  fgt_passive = false
}
# Create VPC FGT
module "fgt_vpc" {
  source = "git::github.com/jmvigueras/modules//aws/vpc-fgt-2az_tgw"

  prefix     = "${local.prefix}-onramp"
  admin_cidr = local.admin_cidr
  admin_port = local.admin_port
  region     = local.region

  vpc-sec_cidr = local.fgt_vpc_cidr

  tgw_id                = module.tgw.tgw_id
  tgw_rt-association_id = module.tgw.rt_default_id
  tgw_rt-propagation_id = module.tgw.rt_vpc-spoke_id
}
#--------------------------------------------------------------------------
# Create SSM parameters to store FGT details
#--------------------------------------------------------------------------
resource "aws_ssm_parameter" "fgt_host" {
  name  = "${local.param_path}/fgt_host"
  type  = "String"
  value = "${module.fgt.fgt_active_eip_mgmt}:${local.admin_port}"
}
resource "aws_ssm_parameter" "fgt_api_key" {
  name  = "${local.param_path}/fgt_api_key"
  type  = "String"
  value = trimspace(random_string.api_key.result)
}
resource "aws_ssm_parameter" "fgt_external_ip" {
  name  = "${local.param_path}/fgt_external_ip"
  type  = "String"
  value = module.fgt_vpc.fgt-active-ni_ips["public"]
}
resource "aws_ssm_parameter" "fgt_public_ip" {
  name  = "${local.param_path}/fgt_public_ip"
  type  = "String"
  value = module.fgt.fgt_active_eip_public
}
resource "aws_ssm_parameter" "node_worker_ip" {
  name  = "${local.param_path}/node_worker_ip"
  type  = "String"
  value = cidrhost(local.nodes_subnet_cidr, local.node_master_cidrhost + 1)
}