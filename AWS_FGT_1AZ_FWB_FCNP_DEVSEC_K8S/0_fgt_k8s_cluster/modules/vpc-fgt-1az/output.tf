output "fgt-active-ni_ids" {
  value = {
    mgmt    = aws_network_interface.ni-active-mgmt.id
    public  = aws_network_interface.ni-active-public.id
    private = aws_network_interface.ni-active-private.id
  }
}

output "fgt-active-ni_ips" {
  value = {
    mgmt    = local.fgt-1_ni_mgmt_ip
    public  = local.fgt_ni_public_ip_float
    private = local.fgt_ni_private_ip_float
  }
}

output "fgt-passive-ni_ids" {
  value = {
    mgmt    = aws_network_interface.ni-passive-mgmt.id
    public  = aws_network_interface.ni-passive-public.id
    private = aws_network_interface.ni-passive-private.id
  }
}

output "fgt-passive-ni_ips" {
  value = {
    mgmt    = local.fgt-2_ni_mgmt_ip
    public  = local.fgt_ni_public_ip_float
    private = local.fgt_ni_private_ip_float
  }
}

output "subnet_az1_cidrs" {
  value = {
    mgmt    = aws_subnet.subnet-az1-mgmt-ha.cidr_block
    public  = aws_subnet.subnet-az1-public.cidr_block
    private = aws_subnet.subnet-az1-private.cidr_block
    bastion = aws_subnet.subnet-az1-bastion.cidr_block
    tgw     = aws_subnet.subnet-az1-tgw.cidr_block
    gwlb    = aws_subnet.subnet-az1-gwlb.cidr_block
  }
}


output "subnet_az1_ids" {
  value = {
    mgmt    = aws_subnet.subnet-az1-mgmt-ha.id
    public  = aws_subnet.subnet-az1-public.id
    private = aws_subnet.subnet-az1-private.id
    bastion = aws_subnet.subnet-az1-bastion.id
    tgw     = aws_subnet.subnet-az1-tgw.id
    gwlb    = aws_subnet.subnet-az1-gwlb.id
  }
}

output "vpc-sec_id" {
  value = aws_vpc.vpc-sec.id
}

output "nsg_ids" {
  value = {
    mgmt      = aws_security_group.nsg-vpc-sec-mgmt.id
    ha        = aws_security_group.nsg-vpc-sec-ha.id
    private   = aws_security_group.nsg-vpc-sec-private.id
    public    = aws_security_group.nsg-vpc-sec-public.id
    bastion   = aws_security_group.nsg-vpc-sec-bastion.id
    allow_all = aws_security_group.nsg-vpc-sec-allow-all.id
  }
}

/*
output "bastion-ni_ids" {
  value = {
    az1 = aws_network_interface.ni-bastion-az1.id
  }
}

output "bastion-ni_ips" {
  value = {
    az1 = aws_network_interface.ni-bastion-az1.private_ip
  }
}

output "faz_ni_ids" {
  value = {
    public  = aws_network_interface.ni-faz-public.id
    private = aws_network_interface.ni-faz-private.id
  }
}

output "faz_ni_ips" {
  value = {
    public  = aws_network_interface.ni-faz-public.private_ip
    private = aws_network_interface.ni-faz-private.private_ip
  }
}

output "fmg_ni_ids" {
  value = {
    public  = aws_network_interface.ni-fmg-public.id
    private = aws_network_interface.ni-fmg-private.id
  }
}

output "fmg_ni_ips" {
  value = {
    public  = aws_network_interface.ni-fmg-public.private_ip
    private = aws_network_interface.ni-fmg-private.private_ip
  }
}

output "fgt_active_eip_mgmt" {
  value = aws_eip.fgt_active_eip_mgmt.public_ip
}

output "fgt_passive_eip_mgmt" {
  value = aws_eip.fgt_passive_eip_mgmt.public_ip
}

output "fgt_active_eip_public" {
  value = aws_eip.fgt_active_eip_public.public_ip
}

output "fgt_passive_eip_public" {
  value = aws_eip.fgt_passive_eip_public.public_ip
}
*/