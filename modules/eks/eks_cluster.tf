module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "18.31.2"

  cluster_name    = "${var.cluster_name}-${var.stage}"
  cluster_version = var.cluster_version

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  eks_managed_node_group_defaults = var.eks_managed_node_group_defaults

  # Required for Karpenter role
  enable_irsa = var.karpenter_autoscaling

  node_security_group_tags = merge(
    var.node_security_group_tags,
    var.karpenter_autoscaling ? {
      "karpenter.sh/discovery" =  "${var.cluster_name}-${var.stage}"
    } : {}
  )
  
  node_security_group_additional_rules = var.karpenter_autoscaling ? {
      ingress_nodes_karpenter_port = {
        description                   = "Cluster API to Node group for Karpenter webhook"
        protocol                      = "tcp"
        from_port                     = 8443
        to_port                       = 8443
        type                          = "ingress"
        source_cluster_security_group = true
      }
    } : {}

  eks_managed_node_groups = {
    medium_group = {
      name                   = var.cluster_node_name
      instance_types         = [var.eks_instance_type]
      min_size               = var.cluster_min_size
      max_size               = var.cluster_max_size
      desired_size           = var.cluster_desired_size
      vpc_security_group_ids = [
        aws_security_group.small_node_group.id
      ]
    }
  }

  # Allow setting access permissions to the eks cluster (e.g., who can run kubectl commands) via aws-auth configmap
  manage_aws_auth_configmap = var.manage_aws_auth_configmap

  # Allow all users in an AWS environment with the "AWSAdministratorAccess" role to run kubectl commands
  aws_auth_roles = concat(
    var.manage_aws_auth_configmap ? [
      {
        rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${tolist(data.aws_iam_roles.admin_role.names)[0]}"
        username = "AWSAdministratorAccess:{{SessionName}}"
        groups = [
          "system:masters",
        ]
      }
    ] : [],
    var.karpenter_autoscaling ? [
      {
        rolearn  = module.karpenter[0].role_arn
        username = "system:node:{{EC2PrivateDNSName}}"
        groups = [
          "system:bootstrappers",
          "system:nodes",
        ]
      }
    ] : []
  )
}
