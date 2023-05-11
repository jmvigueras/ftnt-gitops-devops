#------------------------------------------------------------------
# Create FGT 
# - Create cluster FGCP config
# - Create FGCP instances
# - Create vNet
# - Create LB
#------------------------------------------------------------------
module "fgt_site_config" {
  source = "git::github.com/jmvigueras/modules//azure/fgt-config"

  admin_cidr     = local.admin_cidr
  admin_port     = local.admin_port
  rsa-public-key = trimspace(tls_private_key.ssh.public_key_openssh)
  api_key        = trimspace(random_string.api_key.result)

  subnet_cidrs       = module.fgt_site_vnet.subnet_cidrs
  fgt-active-ni_ips  = module.fgt_site_vnet.fgt-active-ni_ips
  fgt-passive-ni_ips = module.fgt_site_vnet.fgt-passive-ni_ips

  # Config for SDN connector
  # - API calls
  subscription_id     = var.subscription_id
  client_id           = var.client_id
  client_secret       = var.client_secret
  tenant_id           = var.tenant_id
  resource_group_name = local.resource_group_name == null ? azurerm_resource_group.rg[0].name : local.resource_group_name
  # - HA failover
  route_table          = "${local.prefix}-rt-default"
  cluster_pip          = module.fgt_site_vnet.fgt-active-public-name
  fgt-active-ni_names  = module.fgt_site_vnet.fgt-active-ni_names
  fgt-passive-ni_names = module.fgt_site_vnet.fgt-passive-ni_names
  # -

  config_fgcp  = true
  config_spoke = true
  config_fmg   = true
  config_faz   = true

  spoke  = local.spoke
  hubs   = local.hubs
  fmg_ip = module.fgt_hub_vpc.fmg_ni_ips["private"]
  faz_ip = module.fgt_hub_vpc.faz_ni_ips["private"]

  vpc-spoke_cidr = [module.fgt_site_vnet.subnet_cidrs["bastion"]]
}
// Create FGT cluster spoke
// (Example with a full scenario deployment with all modules)
module "fgt_site" {
  source = "git::github.com/jmvigueras/modules//azure/fgt-ha"

  prefix                   = local.prefix
  location                 = local.location
  resource_group_name      = local.resource_group_name == null ? azurerm_resource_group.rg[0].name : local.resource_group_name
  tags                     = local.tags
  storage-account_endpoint = local.storage-account_endpoint == null ? azurerm_storage_account.storageaccount[0].primary_blob_endpoint : local.storage-account_endpoint

  admin_username = local.admin_username
  admin_password = local.admin_password

  fgt-active-ni_ids  = module.fgt_site_vnet.fgt-active-ni_ids
  fgt-passive-ni_ids = module.fgt_site_vnet.fgt-passive-ni_ids
  fgt_config_1       = module.fgt_site_config.fgt_config_1
  fgt_config_2       = module.fgt_site_config.fgt_config_2

  fgt_passive  = false
  license_type = local.az_license_type
  fgt_version  = local.az_fgt_version
  size         = local.az_fgt_size
}
// Module VNET for FGT
// - This module will generate VNET and network intefaces for FGT cluster
module "fgt_site_vnet" {
  source = "git::github.com/jmvigueras/modules//azure/vnet-fgt"

  prefix              = local.prefix
  location            = local.location
  resource_group_name = local.resource_group_name == null ? azurerm_resource_group.rg[0].name : local.resource_group_name
  tags                = local.tags

  vnet-fgt_cidr = local.az_fgt_vnet_cidr
  admin_port    = local.admin_port
  admin_cidr    = local.admin_cidr
}
#--------------------------------------------------------------------------------
# Create route table default (example of route table)
#--------------------------------------------------------------------------------
// Route-table definition
resource "azurerm_route_table" "rt-default" {
  name                = "${local.prefix}-rt-default"
  location            = local.location
  resource_group_name = local.resource_group_name == null ? azurerm_resource_group.rg[0].name : local.resource_group_name

  disable_bgp_route_propagation = false

  route {
    name                   = "default"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = module.fgt_site_vnet.fgt-active-ni_ips["private"]
  }
}
#--------------------------------------------------------------------------------
# Create bastion VM
#--------------------------------------------------------------------------------
module "vm_site" {
  source = "git::github.com/jmvigueras/modules//azure/new-vm_rsa-ssh_v2"

  prefix                   = "${local.prefix}-site"
  location                 = local.location
  resource_group_name      = local.resource_group_name == null ? azurerm_resource_group.rg[0].name : local.resource_group_name
  tags                     = local.tags
  storage-account_endpoint = local.storage-account_endpoint == null ? azurerm_storage_account.storageaccount[0].primary_blob_endpoint : local.storage-account_endpoint
  admin_username           = local.admin_username
  rsa-public-key           = trimspace(tls_private_key.ssh.public_key_openssh)

  subnet_id   = module.fgt_site_vnet.subnet_ids["bastion"]
  subnet_cidr = module.fgt_site_vnet.subnet_cidrs["bastion"]
}