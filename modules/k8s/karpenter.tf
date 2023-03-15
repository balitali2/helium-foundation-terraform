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
  yaml_body = <<-YAML
    apiVersion: karpenter.sh/v1alpha5
    kind: Provisioner
    metadata:
      name: default
    spec:
      ttlSecondsAfterEmpty: 60 # scale down nodes after 60 seconds without workloads (excluding daemons)
      limits:
        resources:
          cpu: 1000
          memory: 1000Gi # limit to 100 CPU cores
      requirements:
        # Include general purpose instance families
        - key: karpenter.k8s.aws/instance-family
          operator: In
          values: [m5]
        # Exclude small instance sizes
        - key: karpenter.k8s.aws/instance-size
          operator: NotIn
          values: [nano, micro, small]
        - key: "kubernetes.io/arch"
          operator: In
          values: ["amd64"]
      consolidation:
        enabled: true
      providerRef:
        name: provider
  YAML

  depends_on = [helm_release.karpenter]
}

resource "kubectl_manifest" "karpenter_node_template" {
  yaml_body = <<-YAML
    apiVersion: karpenter.k8s.aws/v1alpha1
    kind: AWSNodeTemplate
    metadata:
      name: provider
    spec:
      subnetSelector:
        karpenter.sh/discovery: "true"
      securityGroupSelector:
        karpenter.sh/discovery: ${data.aws_eks_cluster.eks.name}
      tags:
        karpenter.sh/discovery: ${data.aws_eks_cluster.eks.name}
  YAML

  depends_on = [
    helm_release.karpenter
  ]
}