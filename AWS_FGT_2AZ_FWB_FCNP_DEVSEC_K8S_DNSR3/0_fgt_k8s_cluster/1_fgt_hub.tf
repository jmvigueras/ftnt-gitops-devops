#------------------------------------------------------------------------------
# Create hub 1
# - VPC FGT hub
# - config FGT hub (FGCP)
# - FGT hub
# - Create test instances in bastion subnet
#------------------------------------------------------------------------------
// Create VPC for hub
module "fgt_hub_vpc" {
  source = "git::github.com/jmvigueras/modules//aws/vpc-fgt-2az"

  prefix     = "${local.prefix}-hub"
  admin_cidr = local.admin_cidr
  admin_port = local.admin_port
  region     = local.region

  vpc-sec_cidr = local.hub_vpc_cidr
}
// Create config for FGT hub (FGCP)
module "fgt_hub_config" {
  source = "git::github.com/jmvigueras/modules//aws/fgt-config"

  admin_cidr     = local.admin_cidr
  admin_port     = local.admin_port
  rsa-public-key = trimspace(tls_private_key.ssh.public_key_openssh)
  api_key        = trimspace(random_string.api_key.result)

  subnet_active_cidrs  = module.fgt_hub_vpc.subnet_az1_cidrs
  subnet_passive_cidrs = module.fgt_hub_vpc.subnet_az1_cidrs
  fgt-active-ni_ips    = module.fgt_hub_vpc.fgt-active-ni_ips
  fgt-passive-ni_ips   = module.fgt_hub_vpc.fgt-passive-ni_ips

  config_fgcp = true
  config_hub  = true
  config_fmg  = true
  config_faz  = true

  fmg_ip = module.fmg.ni_ips["private"]
  faz_ip = module.faz.ni_ips["private"]
  hub    = local.hub

  vpc-spoke_cidr = [module.fgt_hub_vpc.subnet_az1_cidrs["bastion"]]
}
// Create FGT instances (Active-Active)
module "fgt_hub" {
  source = "git::github.com/jmvigueras/modules//aws/fgt-ha"

  prefix        = "${local.prefix}-hub"
  region        = local.region
  instance_type = local.fgt_instance_type
  keypair       = aws_key_pair.keypair.key_name

  license_type = local.fgt_license_type
  fgt_build    = local.fgt_build

  fgt-active-ni_ids  = module.fgt_hub_vpc.fgt-active-ni_ids
  fgt-passive-ni_ids = module.fgt_hub_vpc.fgt-passive-ni_ids
  fgt_config_1       = module.fgt_hub_config.fgt_config_1
  fgt_config_2       = module.fgt_hub_config.fgt_config_2

  fgt_passive = false
}
// Create VM in bastion subnet
resource "aws_instance" "vm_fgt_hub" {
  depends_on                  = [module.faz, module.fmg]
  ami                         = "ami-0c06c45b5455eb326"
  instance_type               = "t2.medium"
  key_name                    = aws_key_pair.keypair.key_name
  get_password_data           = true
  subnet_id                   = module.fgt_hub_vpc.subnet_az1_ids["bastion"]
  vpc_security_group_ids      = [module.fgt_hub_vpc.nsg_ids["bastion"]]
  associate_public_ip_address = true

  user_data = base64encode(data.template_file.win_ps_script.rendered)

  tags = {
    Name    = "${local.prefix}-hub-vm"
    Project = local.prefix
  }
}

# Create Dockerfile from template
data "template_file" "win_ps_script" {
  template = file("./templates/win_ps_script.tpl")
  vars = {
    github_token = var.github_token
    github_site  = local.github_site
  }
}