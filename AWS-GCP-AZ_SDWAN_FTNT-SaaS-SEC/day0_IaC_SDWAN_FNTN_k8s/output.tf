# Output
output "aws_fgt_onramp" {
  value = {
    fgt-1_mgmt = "https://${module.fgt.fgt_active_eip_mgmt}:${local.admin_port}"
    #fgt-2_mgmt   = module.fgt.fgt_passive_eip_mgmt
    fgt-1_public = module.fgt.fgt_active_eip_public
    username     = "admin"
    fgt-1_pass   = module.fgt.fgt_active_id
    #fgt-2_pass   = module.fgt.fgt_passive_id
    admin_cidr = "${chomp(data.http.my-public-ip.response_body)}/32"
    api_key    = module.fgt_config.api_key
  }
}
output "gcp_fgt_hub" {
  value = {
    fgt-1_mgmt = "https://${module.fgt_hub.fgt_active_eip_mgmt}:${local.admin_port}"
    # fgt-2_mgmt   = module.fgt_hub.fgt_passive_eip_mgmt
    # fgt-1_public = module.fgt_hub.fgt_active_eip_public
    username   = "admin"
    fgt-1_pass = module.fgt_hub.fgt_active_id
    # fgt-2_pass   = module.fgt_hub.fgt_passive_id
    admin_cidr = "${chomp(data.http.my-public-ip.response_body)}/32"
    # api_key      = module.fgt_hub_config.api_key
  }
}
output "azure_fgt_site" {
  value = {
    admin        = local.admin_username
    pass         = local.admin_password
    // api_key      = module.fgt_config.api_key
    active_mgmt  = "https://${module.fgt_site_vnet.fgt-active-mgmt-ip}:${local.admin_port}"
    //passive_mgmt = "https://${module.fgt_vnet.fgt-passive-mgmt-ip}:${local.admin_port}"
    //vpn_psk      = module.fgt_config.vpn_psk
  }
}

output "node_master" {
  value = module.node_master.vm
}

output "node_worker" {
  value = module.node_worker.*.vm
}

output "kubectl_config" {
  value = {
    command_1 = "export KUBE_HOST=${module.fgt.fgt_active_eip_public}:${local.api_port}"
    command_2 = "export KUBE_TOKEN=$(aws ssm get-parameter --name ${local.param_path}/cicd-access_token --with-decryption | jq -r '.Parameter.Value')"
    command_3 = "aws ssm get-parameter --name ${local.param_path}/master_ca_cert --with-decryption | jq -r '.Parameter.Value' | base64 --decode >ca.crt"
    command_4 = "kubectl get nodes --token $KUBE_TOKEN -s https://$KUBE_HOST --certificate-authority ca.crt"
  }
}

output "faz" {
  value = {
    mgmt_url   = "https://${module.faz.faz_public-ip}"
    admin_user = "admin"
    admin_pass = module.faz.faz_id
  }
}
output "fmg" {
  value = {
    mgmt_url   = "https://${module.fmg.fmg_public-ip}"
    admin_user = "admin"
    admin_pass = module.fmg.fmg_id
  }
}

output "vm_site" {
  value = module.vm_site.vm
}