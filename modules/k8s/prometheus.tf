resource "helm_release" "prometheus" {
  count = var.with_central_monitoring ? 1 : 0

  name             = "prometheus"
  chart            = "prometheus"
  version          = "20.0.2"
  namespace        = "monitoring"
  repository       = "https://prometheus-community.github.io/helm-charts"
  create_namespace = true
  cleanup_on_fail  = true 

  set {
    name  = "forceNamespace"
    value = "monitoring"
  }

  set {
    name  = "serviceAccounts.server.annotations.eks\\.amazonaws\\.com/role-arn"
    value = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/EKS-AMP-ServiceAccount-Role"
  }

  set {
    name  = "server.statefulSet.enabled"
    value = true
  }

  set {
    name  = "server.persistentVolume.enabled"
    value = false
  }

  set {
    name  = "server.retention"
    value = "6h"
  }

  set {
    name  = "server.remoteWrite[0].url"
    value = var.prometheus_remote_write_url
  }

  set {
    name  = "server.remoteWrite[0].name"
    value = "${var.env}-${var.stage}"
  }

  set {
    name  = "server.remoteWrite[0].queue_config.max_samples_per_send"
    value = 1000
  }

  set {
    name  = "server.remoteWrite[0].queue_config.max_shards"
    value = 200
  }

  set {
    name  = "server.remoteWrite[0].queue_config.capacity"
    value = 2500
  }

  set {
    name  = "server.remoteWrite[0].sigv4.region"
    value = var.monitoring_account_region
  }

  set {
    name  = "server.remoteWrite[0].sigv4.role_arn"
    value = "arn:aws:iam::${var.monitoring_account_id}:role/EKS-AMP-Central-Role"
  }

  set {
    name = "server\\.resources"
    value = yamlencode({
      limits = {
        cpu    = "200m"
        memory = "50Mi"
      }
      requests = {
        cpu    = "100m"
        memory = "30Mi"
      }
    })
  }
}