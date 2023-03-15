data "kubectl_path_documents" "nginx" {
  pattern = "${path.module}/lb/ingress-nginx.yaml"
  vars = {
    cert = var.zone_cert
    cidr = var.cidr_block
  }
}

data "kubectl_path_documents" "application" {
  pattern = "${path.module}/argocd/application.yaml"
  vars = {
    path = var.argo_path
  }
}

data "kubectl_path_documents" "karpenter" {
  pattern = "${path.module}/karpenter/provisioner.yaml"
  vars = {
    eks_name = data.aws_eks_cluster.eks.name
  }
}

data "aws_eks_cluster" "eks" {
  name = local.cluster_name
}

data "aws_eks_cluster_auth" "eks" {
  name = local.cluster_name
}

data "aws_caller_identity" "current" {}

data "aws_ecrpublic_authorization_token" "token" {
  provider = aws.virginia
}

data "aws_ssm_parameter" "is_karpenter_deployed" {
  name = "/eks/karpenter/is_deployed"
}

data "aws_ssm_parameter" "karpenter_irsa_arn" {
  name = "/eks/karpenter/irsa_arn"
}

data "aws_ssm_parameter" "karpenter_instance_profile_name" {
  name = "/eks/karpenter/instance_profile_name"
}

data "aws_ssm_parameter" "karpenter_queue_name" {
  name = "/eks/karpenter/queue_name"
}