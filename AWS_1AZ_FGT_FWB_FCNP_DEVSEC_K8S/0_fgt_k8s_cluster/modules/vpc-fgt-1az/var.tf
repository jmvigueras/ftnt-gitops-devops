# AWS resourcers prefix description
variable "prefix" {
  type    = string
  default = "terraform"
}

# AWS resourcers prefix description
variable "tag-env" {
  type    = string
  default = "terraform-deploy"
}

variable "tags" {
  description = "Attribute for tag Enviroment"
  type        = map(any)
  default = {
    owner   = "terraform"
    project = "terraform-deploy"
  }
}

variable "admin_cidr" {
  type    = string
  default = "0.0.0.0/0"
}

variable "admin_port" {
  type    = string
  default = "8443"
}

variable "vpc-sec_cidr" {
  type    = string
  default = "172.30.0.0/23"
}

variable "tgw_id" {
  type    = string
  default = null
}

variable "gwlb_service-name" {
  type    = string
  default = null
}

variable "region" {
  type = map(any)
  default = {
    id  = "eu-west-1"
    az1 = "eu-west-1a"
    az2 = "eu-west-1c"
  }
}