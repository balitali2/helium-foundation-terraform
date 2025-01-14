provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Terraform = "true"
      Environment = var.env
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
  deploy_cost_infrastructure      = var.deploy_cost_infrastructure
  create_nova_dependent_resources = var.create_nova_dependent_resources

  # AWS
  aws_region = var.aws_region
  aws_azs    = var.aws_azs

  # VPC
  vpc_name           = var.vpc_name
  cidr_block         = var.cidr_block
  public_subnets     = var.public_subnets
  private_subnets    = var.private_subnets
  database_subnets   = var.database_subnets
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
# RDS
# ***************************************
module "rds" {
  count = var.deploy_cost_infrastructure ? 1 : 0

  source = "../modules/rds"

  # Env
  env                             = var.env
  stage                           = var.stage
  create_nova_dependent_resources = var.create_nova_dependent_resources

  # AWS
  aws_region = var.aws_region

  # RDS
  rds_instance_type    = var.rds_instance_type
  rds_storage_type     = var.rds_storage_type
  rds_storage_size     = var.rds_storage_size
  rds_max_storage_size = var.rds_max_storage_size

  # Db
  db_name           = "web"
  db_identifier     = "web-rds"
  db_engine         = "postgres"
  db_username       = "web_admin"
  db_log_exports    = ["postgresql"]
  db_port           = 5432
  db_engine_version = var.rds_engine_version
  db_multi_az       = var.rds_multi_az

  # IAM
  oidc_provider     = module.eks[0].oidc_provider
  oidc_provider_arn = module.eks[0].oidc_provider_arn
  eks_cluster_name  = var.cluster_name

  # Snapshot restore
  deploy_from_snapshot = var.deploy_from_snapshot
  snapshot_identifier  = var.private_snapshot_identifier

  # Networking & Security
  vpc_id                 = module.vpc.vpc_id
  ec2_bastion_private_ip = var.ec2_bastion_private_ip
  database_subnets       = var.database_subnets
  private_subnets        = var.private_subnets
  database_subnet_ids    = module.vpc.database_subnet_ids
  db_subnet_group_name   = module.vpc.database_subnet_group_name

  # Monitoring
  cloudwatch_alarm_action_arns = [module.notify_slack.slack_topic_arn]
}

# ***************************************
# Public Monitoring RDS
# ***************************************
module "rds_public" {
  count = var.deploy_cost_infrastructure ? 1 : 0

  source = "../modules/rds-public"

  # Env
  env   = var.env
  stage = var.stage

  # AWS
  aws_region = var.aws_region

  # RDS
  rds_instance_type       = var.rds_instance_type
  rds_storage_type        = var.rds_storage_type
  rds_storage_size        = var.rds_storage_size
  rds_max_storage_size    = var.rds_max_storage_size
  rds_public_read_replica = var.rds_public_read_replica

  # Db
  db_name           = "monitoring"
  db_identifier     = "monitoring-rds"
  db_engine         = "postgres"
  db_username       = "monitoring_admin"
  db_log_exports    = ["postgresql"]
  db_port           = 5432
  db_engine_version = var.rds_engine_version
  db_multi_az       = var.rds_multi_az

  # IAM
  oidc_provider     = module.eks[0].oidc_provider
  oidc_provider_arn = module.eks[0].oidc_provider_arn

  # Networking & Security
  vpc_id               = module.vpc.vpc_id
  public_subnet_ids    = module.vpc.public_subnets

  # Snapshot restore
  deploy_from_snapshot = var.deploy_from_snapshot
  snapshot_identifier  = var.public_snapshot_identifier

  # Monitoring
  cloudwatch_alarm_action_arns = [module.notify_slack.slack_topic_arn]
}

# ***************************************
# Bastion
# ***************************************
module "bastion" {
  count = var.deploy_cost_infrastructure ? 1 : 0

  source = "../modules/bastion"

  # Env
  env   = var.env
  stage = var.stage

  # AWS
  aws_region = var.aws_region
  aws_az     = var.aws_azs[0]

  # Networking & Security
  vpc_id             = module.vpc.vpc_id
  public_subnet_id   = module.vpc.public_subnets[0]
  security_group_ids = [module.rds[0].rds_access_security_group_id, module.rds_public[0].public_rds_access_security_group_id]

  # EC2
  ec2_bastion_ssh_key_name = var.ec2_bastion_ssh_key_name
  ec2_bastion_access_ips   = var.ec2_bastion_access_ips
  ec2_bastion_private_ip   = var.ec2_bastion_private_ip

  # Monitoring
  cloudwatch_alarm_action_arns = [module.notify_slack.slack_topic_arn]
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