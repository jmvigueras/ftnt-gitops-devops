# Output
output "fgt_onramp" {
  value = {
    fgt-1_mgmt = "https://${module.fgt.fgt_active_eip_mgmt}:${local.admin_port}"
    #fgt-2_mgmt   = module.fgt.fgt_passive_eip_mgmt
    fgt-1_public = module.fgt.fgt_active_eip_public
    username     = "admin"
    fgt-1_pass   = module.fgt.fgt_active_id
    #fgt-2_pass   = module.fgt.fgt_passive_id
    admin_cidr = "${chomp(data.http.my-public-ip.body)}/32"
    api_key    = module.fgt_config.api_key
  }
}

output "fgt_hub" {
  value = {
    fgt-1_mgmt = "https://${module.fgt_hub.fgt_active_eip_mgmt}:${local.admin_port}"
    # fgt-2_mgmt   = module.fgt_hub.fgt_passive_eip_mgmt
    # fgt-1_public = module.fgt_hub.fgt_active_eip_public
    username   = "admin"
    fgt-1_pass = module.fgt_hub.fgt_active_id
    # fgt-2_pass   = module.fgt_hub.fgt_passive_id
    admin_cidr = "${chomp(data.http.my-public-ip.body)}/32"
    # api_key      = module.fgt_hub_config.api_key
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

output "api_access" {
  value = "http://${module.fgt.fgt_active_eip_public}:${local.api_port}"
}

output "vm_fgt_hub" {
  value = {
    public_ip = aws_instance.vm_fgt_hub.public_ip
    username  = "Administrator"
    password  = fileexists("./ssh-key/${local.prefix}-ssh-key.pem") ? "${rsadecrypt(aws_instance.vm_fgt_hub.password_data, file("./ssh-key/${local.prefix}-ssh-key.pem"))}" : ""
  }
}

output "faz" {
  value = {
    faz_mgmt = "https://${module.faz.eip_public}"
    faz_pass = module.faz.id
  }
}

output "fmg" {
  value = {
    fmg_mgmt = "https://${module.fmg.eip_public}"
    fmg_pass = module.fmg.id
  }
}