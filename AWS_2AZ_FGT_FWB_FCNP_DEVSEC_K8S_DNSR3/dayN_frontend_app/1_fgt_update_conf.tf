# Define a new VIP resource
resource "fortios_firewall_vip" "app_vip" {
  name = "vip-${local.fgt_secrets["MAPPED_IP"]}-${local.app_nodeport}"

  type        = "static-nat"
  extintf     = "port1"
  extip       = local.fgt_secrets["EXTERNAL_IP"]
  extport     = local.app_nodeport
  mappedport  = local.app_nodeport
  portforward = "enable"

  mappedip {
    range = local.fgt_secrets["MAPPED_IP"]
  }
}
# Define a new firewall policy with default intrusion prevention profile
resource "fortios_firewall_policy" "app_policy" {
  depends_on = [fortios_firewall_vip.app_vip]
  name       = "vip-${local.fgt_secrets["EXTERNAL_IP"]}-${local.app_nodeport}"

  schedule        = "always"
  action          = "accept"
  utm_status      = "enable"
  ips_sensor      = "all_default_pass"
  ssl_ssh_profile = "certificate-inspection"
  nat             = "enable"
  logtraffic      = "all"

  dstintf {
    name = "port2"
  }
  srcintf {
    name = "port1"
  }
  srcaddr {
    name = "all"
  }
  dstaddr {
    name = "vip-${local.fgt_secrets["MAPPED_IP"]}-${local.app_nodeport}"
  }
  service {
    name = "ALL"
  }
}