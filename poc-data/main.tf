provider "aws" {
  region = var.aws_region

  default_tags {
      tags = {
        Terraform = "true"
        Environment = var.stage
      }
  }
}

# Kubernetes provider
# https://learn.hashicorp.com/terraform/kubernetes/provision-eks-cluster#optional-configure-terraform-kubernetes-provider
# To learn how to schedule deployments and services using the provider, go here: https://learn.hashicorp.com/terraform/kubernetes/deploy-nginx-kubernetes
# The Kubernetes provider is included in this file so the EKS module can complete successfully. Otherwise, it throws an error when creating `kubernetes_config_map.aws_auth`.
# You should **not** schedule deployments and services in this workspace. This keeps workspaces modular (one for provision EKS, another for scheduling Kubernetes resources) as per best practices.
provider "kubernetes" {
  host                   = try(module.eks[0].cluster_endpoint, null)
  cluster_ca_certificate = try(base64decode(module.eks[0].cluster_certificate_authority_data), null)
  token                  = try(module.eks[0].aws_eks_cluster_auth, null)
}

# ***************************************
# VPC
# ***************************************
module "vpc" {
  source = "../modules/vpc"

  # Env
  deploy_cost_infrastructure = var.deploy_cost_infrastructure

  # AWS
  aws_region = var.aws_region
  aws_azs    = var.aws_azs

  # VPC
  vpc_name           = var.vpc_name
  cidr_block         = var.cidr_block
  public_subnets     = var.public_subnets
  private_subnets    = var.private_subnets
  public_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}-${var.stage}" = "shared"
    "kubernetes.io/role/elb"                      = 1
  }
  private_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}-${var.stage}" = "shared"
    "kubernetes.io/role/internal-elb"             = 1
  }
}

# ***************************************
# EKS
# ***************************************
module "eks" {
  count = var.deploy_cost_infrastructure ? 1 : 0

  source = "../modules/eks"

  # Env
  env   = var.env
  stage = var.stage

  # AWS
  aws_region = var.aws_region

  # VPC
  vpc_id      = module.vpc.vpc_id
  subnet_ids  = module.vpc.private_subnets
  cidr_block  = var.cidr_block

  # EKS
  cluster_name              = var.cluster_name
  cluster_node_name         = "small-node-group"
  cluster_version           = var.cluster_version
  cluster_min_size          = var.cluster_min_size
  cluster_max_size          = var.cluster_max_size
  cluster_desired_size      = var.cluster_desired_size
  eks_instance_type         = var.eks_instance_type
  manage_aws_auth_configmap = var.manage_aws_auth_configmap
  add_cluster_autoscaler    = var.add_cluster_autoscaler
  node_security_group_tags  = {
    "kubernetes.io/cluster/${var.cluster_name}-${var.stage}" = null
  }

  # Centralized Monitoring
  monitoring_account_id = var.monitoring_account_id
}

# ***************************************
# Slack Alarm Notification Infra
# ***************************************
module "notify_slack" {
  source  = "terraform-aws-modules/notify-slack/aws"
  version = "5.6.0"

  sns_topic_name = "slack-topic"

  slack_webhook_url = var.slack_webhook_url
  slack_channel     = var.slack_channel
  slack_username    = "reporter"

  # Prevent Terraform Cloud drift on null_resource
  recreate_missing_package = false
}

# ***************************************
# Budget & Cost Anomaly
# ***************************************
module "budget" {
  source = "../modules/budget"

  # Env
  env   = var.env
  stage = var.stage

  # Budget
  budget_amount     = var.budget_amount
  budget_email_list = var.budget_email_list

  # Cost Anomaly
  raise_amount_percent  = var.raise_amount_percent
  raise_amount_absolute = var.raise_amount_absolute
  slack_email           = var.slack_email
}