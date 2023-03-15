module "karpenter" {
  count = var.karpenter_autoscaling ? 1 : 0

  source = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "18.31.2"

  cluster_name = module.eks.cluster_name

  irsa_oidc_provider_arn          = module.eks.oidc_provider_arn
  irsa_namespace_service_accounts = ["karpenter:karpenter"]

  create_iam_role = false
  iam_role_arn    = module.eks.eks_managed_node_groups["medium_group"].iam_role_arn
}