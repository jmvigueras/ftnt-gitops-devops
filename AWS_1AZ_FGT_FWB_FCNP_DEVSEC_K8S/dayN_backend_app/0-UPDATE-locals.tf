locals {
  #---------------------------------------------------------------------
  # General variables
  #---------------------------------------------------------------------
  param_path = "/fgt-k8s-cicd"

  #---------------------------------------------------------------------
  # Github repo variables
  #---------------------------------------------------------------------
  github_site      = "secdayforti"
  github_repo_name = local.app_name

  git_author_email = "secdayforti@gmail.com"
  git_author_name  = "secdayforti"

  #---------------------------------------------------------------------
  # Github repo secrets
  #---------------------------------------------------------------------
  # Docker repository details
  # - Necessary variable to point image to deploy first time
  # - Secrets to mapped to github to future image deployments
  dockerhub_username      = "jviguerasfortinet"
  dockerhub_image_name    = "vuln-flask-app"
  dockerhub_image_version = "v1"
  dockerhub_image_tag     = "${local.dockerhub_username}/${local.dockerhub_image_name}:${local.dockerhub_image_version}"

  dockerhub_secrets = {
    DOCKERHUB_TOKEN    = var.dockerhub_token
    DOCKERHUB_USERNAME = local.dockerhub_username
  }
  # K8S cluster API access (get secrets from AWS SSM) 
  # - Define AWS region
  # - Define path for SSM parameters
  # - Mapped SSM parameters to Github access secrets
  region = {
    id = "eu-west-1"
  }
  aws_ssm_param_path = local.param_path
  aws_ssm_secrets = {
    KUBE_TOKEN       = "cicd-access_token"
    KUBE_HOST        = "master_public_host"
    KUBE_CERTIFICATE = "master_ca_cert"
  }

  #---------------------------------------------------------------------
  # K8S app details
  #---------------------------------------------------------------------
  # variables used in deployment manifest
  app_name     = "backend"
  app_port     = "5000"
  app_nodeport = "30090"
  app_replicas = "1"

  #---------------------------------------------------------------------
  # FGT secrets for FortiOS provider
  #---------------------------------------------------------------------
  fgt_ssm_param_path = local.param_path
  fgt_ssm_secrets = {
    HOST        = "fgt_host"
    TOKEN       = "fgt_api_key"
    EXTERNAL_IP = "fgt_external_ip"
    PUBLIC_IP   = "fgt_public_ip"
    MAPPED_IP   = "node_worker_ip"
  }
  fgt_secrets = {
    HOST        = data.aws_ssm_parameter.fgt_host["HOST"].value
    TOKEN       = data.aws_ssm_parameter.fgt_host["TOKEN"].value
    EXTERNAL_IP = data.aws_ssm_parameter.fgt_host["EXTERNAL_IP"].value
    PUBLIC_IP   = data.aws_ssm_parameter.fgt_host["PUBLIC_IP"].value
    MAPPED_IP   = data.aws_ssm_parameter.fgt_host["MAPPED_IP"].value
  }
}

# Read FGT parameters from AWS SSM
data "aws_ssm_parameter" "fgt_host" {
  for_each = local.fgt_ssm_secrets
  name     = "${local.fgt_ssm_param_path}/${each.value}"
}