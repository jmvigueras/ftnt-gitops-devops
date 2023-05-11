# Output
output "github_repo" {
  value = "https://github.com/${local.github_site}/${local.github_repo_name}.git"
}

output "app_url" {
  value = "http://${local.app_name}.${data.aws_route53_zone.route53_zone.name}"
}

output "fw_cloud_url" {
  value = "http://${data.local_file.fwb_cloud_app_cname.content}"
}

output "server_url" {
  sensitive = true
  value = "http://${local.fgt_secrets["PUBLIC_IP"]}:${local.app_nodeport}"
}