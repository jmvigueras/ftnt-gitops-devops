#-----------------------------------------------------------------------------------------------------
# Create Github repo and actions secret
#-----------------------------------------------------------------------------------------------------
# Create new repository in Github
resource "github_repository" "repo" {
  name        = local.github_repo_name
  description = "An example repository created using Terraform"
}
# Read K8S master parameter from AWS SSM
data "aws_ssm_parameter" "aws_ssm_secrets" {
  for_each = local.aws_ssm_secrets
  name     = "${local.aws_ssm_param_path}/${each.value}"
}
# Create K8S master secrets
resource "github_actions_secret" "aws_ssm_secrets" {
  for_each        = local.aws_ssm_secrets
  depends_on      = [github_repository.repo]
  repository      = github_repository.repo.name
  secret_name     = each.key
  plaintext_value = data.aws_ssm_parameter.aws_ssm_secrets[each.key].value
}
# Create dockers secrets
resource "github_actions_secret" "dockerhub_secrets" {
  for_each        = local.dockerhub_secrets
  depends_on      = [github_repository.repo]
  repository      = github_repository.repo.name
  secret_name     = each.key
  plaintext_value = each.value
}
#-----------------------------------------------------------------------------------------------------
# Update local repo-content
#-----------------------------------------------------------------------------------------------------
# Create Github actions workflow from template
data "template_file" "github_actions_workflow" {
  template = file("./templates/github-actions-workflow.tpl")
  vars = {
    dockerhub_username   = local.dockerhub_username
    dockerhub_image_name = local.dockerhub_image_name
    app_name             = local.app_name
  }
}
resource "local_file" "github_actions_workflow" {
  content  = data.template_file.github_actions_workflow.rendered
  filename = "./repo-content/.github/workflows/main.yaml"
}
# Create k8s manifest from template
data "template_file" "k8s_manifest_deployment" {
  template = file("./templates/k8s-deployment.tpl")
  vars = {
    app_name            = local.app_name
    app_port            = local.app_port
    app_nodeport        = local.app_nodeport
    app_replicas        = local.app_replicas
    dockerhub_image_tag = local.dockerhub_image_tag
  }
}
resource "local_file" "k8s_manifest_deployment" {
  content  = data.template_file.k8s_manifest_deployment.rendered
  filename = "./repo-content/manifest/app-deployment.yaml"
}
# Create file for FortiDevSec manifest from template
data "template_file" "fdevsec_file" {
  template = file("./templates/fdevsec.yaml.tpl")
  vars = {
    devsc_org = var.devsc_org
    devsc_app = var.devsc_app
    app_url   = "http://${local.fgt_secrets["PUBLIC_IP"]}:${local.app_nodeport}"
  }
}
resource "local_file" "fdevsec_file" {
  content  = data.template_file.fdevsec_file.rendered
  filename = "./repo-content/fdevsec.yaml"
}
#-----------------------------------------------------------------------------------------------------
# Upload content to new repo
#-----------------------------------------------------------------------------------------------------
# Upload content to new repo
resource "null_resource" "upload_repo_code" {
  depends_on = [github_repository.repo, github_actions_secret.aws_ssm_secrets, github_actions_secret.dockerhub_secrets]
  provisioner "local-exec" {
    command = "cd ./repo-content && rm -rf .git && git init && git add . && git commit -m 'first commit' && git branch -M master && git remote add origin https://${var.github_token}@github.com/${local.github_site}/${local.github_repo_name}.git && git push -u origin master"
    environment = {
      GIT_AUTHOR_EMAIL = local.git_author_email
      GIT_AUTHOR_NAME  = local.git_author_name
    }
  }
}