resource "helm_release" "karpenter" {
  count = data.aws_ssm_parameter.is_karpenter_deployed == "true" ? 1 : 0

  namespace        = "karpenter"
  create_namespace = true

  name                = "karpenter"
  repository          = "oci://public.ecr.aws/karpenter"
  repository_username = data.aws_ecrpublic_authorization_token.token.user_name
  repository_password = data.aws_ecrpublic_authorization_token.token.password
  chart               = "karpenter"
  version             = "v0.20.0"

  set {
    name  = "settings.aws.clusterName"
    value = data.aws_eks_cluster.eks.name
  }

  set {
    name  = "settings.aws.clusterEndpoint"
    value = data.aws_eks_cluster.eks.endpoint
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = data.aws_ssm_parameter.karpenter_irsa_arn
  }

  set {
    name  = "settings.aws.defaultInstanceProfile"
    value = data.aws_ssm_parameter.karpenter_instance_profile_name
  }

  set {
    name  = "settings.aws.interruptionQueueName"
    value = data.aws_ssm_parameter.karpenter_queue_name
  }
}

resource "kubectl_manifest" "karpenter" {
  depends_on = [helm_release.karpenter]
  count      = length(data.kubectl_path_documents.karpenter.documents)
  yaml_body  = element(data.kubectl_path_documents.karpenter.documents, count.index)
}