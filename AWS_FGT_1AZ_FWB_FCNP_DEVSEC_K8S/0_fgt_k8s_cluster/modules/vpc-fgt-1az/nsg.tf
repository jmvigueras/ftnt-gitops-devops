# Security Groups
## Need to create 4 of them as our Security Groups are linked to a VPC
resource "aws_security_group" "nsg-vpc-sec-mgmt" {
  name        = "${var.prefix}-nsg-vpc-sec-mgmt"
  description = "Allow MGMT SSH, HTTPS and ICMP traffic"
  vpc_id      = aws_vpc.vpc-sec.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.admin_cidr}"]
  }
  ingress {
    from_port   = var.admin_port
    to_port     = var.admin_port
    protocol    = "tcp"
    cidr_blocks = ["${var.admin_cidr}"]
  }
  ingress {
    from_port   = 8 # the ICMP type number for 'Echo'
    to_port     = 0 # the ICMP code
    protocol    = "icmp"
    cidr_blocks = ["${var.admin_cidr}"]
  }
  ingress {
    from_port   = 0 # the ICMP type number for 'Echo Reply'
    to_port     = 0 # the ICMP code
    protocol    = "icmp"
    cidr_blocks = ["${var.admin_cidr}"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.prefix}-nsg-mgmt"
  }
}

resource "aws_security_group" "nsg-vpc-sec-ha" {
  name        = "${var.prefix}-nsg-vpc-sec-ha"
  description = "Allow all traffic for HA"
  vpc_id      = aws_vpc.vpc-sec.id

  ingress {
    description = "Allow all from FGT az1"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_subnet.subnet-az1-mgmt-ha.cidr_block]
  }
  egress {
    description = "Allow all to FGT"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_subnet.subnet-az1-mgmt-ha.cidr_block]
  }

  tags = {
    Name = "${var.prefix}-nsg-ha"
  }
}

resource "aws_security_group" "nsg-vpc-sec-private" {
  name        = "${var.prefix}-nsg-vpc-sec-private"
  description = "Allow all connections from spokes"
  vpc_id      = aws_vpc.vpc-sec.id

  ingress {
    description = "Allow all from spokes"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "Allow all to spokes"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.prefix}-nsg-private"
  }
}

resource "aws_security_group" "nsg-vpc-sec-public" {
  name        = "${var.prefix}-nsg-vpc-sec-public"
  description = "Allow IPSEC ADVPN"
  vpc_id      = aws_vpc.vpc-sec.id

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 8 # the ICMP type number for 'Echo'
    to_port     = 0 # the ICMP code
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 0 # the ICMP type number for 'Echo Reply'
    to_port     = 0 # the ICMP code
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.prefix}-nsg-public"
  }
}

resource "aws_security_group" "nsg-vpc-sec-allow-all" {
  name        = "${var.prefix}-nsg-vpc-sec-allow-all"
  description = "Allow ALL"
  vpc_id      = aws_vpc.vpc-sec.id

  ingress {
    description = "Allow all"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "Allow all"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.prefix}-nsg-private"
  }
}


resource "aws_security_group" "nsg-vpc-sec-bastion" {
  name        = "${var.prefix}-nsg-vpc-sec-bastion"
  description = "Allow all traffic from RFC1918 and admin_cidr"
  vpc_id      = aws_vpc.vpc-sec.id

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["${var.admin_cidr}","192.168.0.0/16","10.0.0.0/8","172.16.0.0/12"]
  }
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "udp"
    cidr_blocks = ["${var.admin_cidr}","192.168.0.0/16","10.0.0.0/8","172.16.0.0/12"]
  }
  ingress {
    from_port   = 8 # the ICMP type number for 'Echo'
    to_port     = 0 # the ICMP code
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 0 # the ICMP type number for 'Echo Reply'
    to_port     = 0 # the ICMP code
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.prefix}-nsg-bastion"
  }
}