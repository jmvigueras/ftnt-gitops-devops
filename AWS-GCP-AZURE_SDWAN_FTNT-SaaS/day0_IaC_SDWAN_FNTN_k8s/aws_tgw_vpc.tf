// Create TGW
module "tgw" {
  source = "git::github.com/jmvigueras/modules//aws/tgw"

  prefix = local.prefix

  tgw_cidr    = local.tgw_cidr
  tgw_bgp-asn = local.tgw_bgp-asn
}
// Create VPC Nodes K8S attached to TGW
module "nodes_vpc" {
  source = "git::github.com/jmvigueras/modules//aws/vpc-spoke-2az-to-tgw"

  prefix     = "${local.prefix}-nodes"
  admin_cidr = local.admin_cidr
  admin_port = local.admin_port
  region     = local.region

  vpc-spoke_cidr = local.nodes_vpc_cidr

  tgw_id                = module.tgw.tgw_id
  tgw_rt-association_id = module.tgw.rt_vpc-spoke_id
  tgw_rt-propagation_id = [module.tgw.rt_default_id, module.tgw.rt-vpc-sec-N-S_id, module.tgw.rt-vpc-sec-E-W_id]
}
// Create static route in TGW RouteTable Spoke
resource "aws_ec2_transit_gateway_route" "nodes_tgw_route" {
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = module.fgt_vpc.vpc_tgw-att_id
  transit_gateway_route_table_id = module.tgw.rt_vpc-spoke_id
}
