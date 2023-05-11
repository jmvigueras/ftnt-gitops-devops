#--------------------------------------------------------------------------
# Create cluster nodes: master and workers
#--------------------------------------------------------------------------
# Create NI for node master
resource "aws_network_interface" "node_master_ni" {
  subnet_id         = module.fgt_vpc.subnet_az1_ids["bastion"]
  security_groups   = [module.fgt_vpc.nsg_ids["bastion"]]
  private_ips       = [cidrhost(module.fgt_vpc.subnet_az1_cidrs["bastion"], local.node_master_cidrhost)]
  source_dest_check = false
  tags = {
    Name = "${local.prefix}-ni-node-master"
  }
}
# Create EIP active public NI for node master
resource "aws_eip" "node_master_eip" {
  vpc               = true
  network_interface = aws_network_interface.node_master_ni.id
  tags = {
    Name = "${local.prefix}-eip-node-master"
  }
}
# Create NI for node master
resource "aws_network_interface" "node_worker_ni" {
  count             = local.worker_number
  subnet_id         = module.fgt_vpc.subnet_az1_ids["bastion"]
  security_groups   = [module.fgt_vpc.nsg_ids["bastion"]]
  private_ips       = [cidrhost(module.fgt_vpc.subnet_az1_cidrs["bastion"], local.node_master_cidrhost + count.index + 1)]
  source_dest_check = false
  tags = {
    Name = "${local.prefix}-ni-node-worker-${count.index + 1}"
  }
}
# Create EIP active public NI for node master
resource "aws_eip" "node_worker_eip" {
  count             = local.worker_number
  vpc               = true
  network_interface = aws_network_interface.node_worker_ni[count.index].id
  tags = {
    Name = "${local.prefix}-eip-node-worker-${count.index + 1}"
  }
}
# Deploy cluster master node
module "node_master" {
  depends_on = [module.fgt]
  source     = "git::github.com/jmvigueras/modules//aws//new-instance_ni"

  prefix  = "${local.prefix}-master"
  keypair = aws_key_pair.keypair.key_name

  instance_type = local.node_instance_type
  disk_size     = local.disk_size
  user_data     = data.template_file.node_master.rendered
  iam_profile   = aws_iam_instance_profile.nodes-apicall-profile.name

  ni_id = aws_network_interface.node_master_ni.id
}
# Deploy cluster worker nodes
module "node_worker" {
  depends_on = [module.fgt, module.node_master, aws_ssm_parameter.master_private_host, aws_ssm_parameter.master_public_host, aws_ssm_parameter.master_token, aws_ssm_parameter.master_ca_cert]
  count      = local.worker_number
  source     = "git::github.com/jmvigueras/modules//aws//new-instance_ni"

  prefix  = "${local.prefix}-worker"
  suffix  = count.index + 1
  keypair = aws_key_pair.keypair.key_name

  instance_type = local.node_instance_type
  disk_size     = local.disk_size
  user_data     = data.template_file.node_worker.rendered
  iam_profile   = aws_iam_instance_profile.nodes-apicall-profile.name

  ni_id = aws_network_interface.node_worker_ni[count.index].id
}
# Create data template for master node
data "template_file" "node_master" {
  depends_on = [module.fgt]
  template   = file("./templates/k8s-master.sh")
  vars = {
    param_path       = local.param_path
    region           = local.region["id"]
    master_public_ip = module.fgt.fgt_active_eip_public
  }
}
# Create data template for worker node
data "template_file" "node_worker" {
  template = file("./templates/k8s-worker.sh")
  vars = {
    param_path = local.param_path
    region     = local.region["id"]
  }
}
#--------------------------------------------------------------------------
# Create SSM parameters to store cluster details
#--------------------------------------------------------------------------
resource "aws_ssm_parameter" "master_private_host" {
  name  = "${local.param_path}/master_private_host"
  type  = "String"
  value = "${module.node_master.vm["private_ip"]}:${local.api_port}"
}
resource "aws_ssm_parameter" "master_public_host" {
  name  = "${local.param_path}/master_public_host"
  type  = "String"
  value = "${module.fgt.fgt_active_eip_public}:${local.api_port}"
}
resource "aws_ssm_parameter" "master_token" {
  name  = "${local.param_path}/master_token"
  type  = "SecureString"
  value = "default"
}
resource "aws_ssm_parameter" "master_ca_cert" {
  name  = "${local.param_path}/master_ca_cert"
  type  = "SecureString"
  value = "default"
}
resource "aws_ssm_parameter" "cicd-access_token" {
  name  = "${local.param_path}/cicd-access_token"
  type  = "SecureString"
  value = "default"
}
#--------------------------------------------------------------------------
# Create the IAM role/profile for the API Call
#--------------------------------------------------------------------------
# Create IAM instance profile role
resource "aws_iam_instance_profile" "nodes-apicall-profile" {
  name = "${local.prefix}-nodes-apicall-profile"
  role = aws_iam_role.nodes-apicall-role.name
}
# Create IAM role
resource "aws_iam_role" "nodes-apicall-role" {
  name = "${local.prefix}-nodes-apicall-role"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
              "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}
# Create IAM role policy
resource "aws_iam_policy" "nodes-apicall-policy" {
  name        = "${local.prefix}-nodes-apicall-policy"
  path        = "/"
  description = "Policies for the k8s nodes api-call Role"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement":
      [
        {
          "Effect": "Allow",
          "Action": 
            [
                "ssm:DescribeParameters",
                "ssm:GetParameters",
                "ssm:GetParameter",
                "ssm:PutParameter",
                "ssm:AddTagsToResource"
            ],
            "Resource": "arn:aws:ssm:*:*:parameter${local.param_path}*"
        }
      ]
}
EOF
}
# Associate Role to policy
resource "aws_iam_policy_attachment" "nodes-apicall-attach" {
  name       = "${local.prefix}-nodes-apicall-attachment"
  roles      = [aws_iam_role.nodes-apicall-role.name]
  policy_arn = aws_iam_policy.nodes-apicall-policy.arn
}