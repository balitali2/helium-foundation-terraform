locals {
  lb_role_name = "${module.eks.cluster_id}-aws-load-balancer-controller"
}

resource "aws_iam_role" "lb" {
  name  = local.lb_role_name

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${var.aws_account_id}:oidc-provider/${local.oidc_url}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "${local.oidc_url}:sub": "system:serviceaccount:kube-system:external-dns"
        }
      }
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "lb" {
  name_prefix = local.lb_role_name
  role        = aws_iam_role.lb.name
  policy      = file("${path.module}/policies/lb.json")
}

resource "kubernetes_service_account" "lb" {
  metadata {
    name      = "lb"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.lb.arn
    }
  }
  automount_service_account_token = true
}

resource "helm_release" "lbc" {
  name             = "aws-load-balancer-controller"
  chart            = "aws-load-balancer-controller"
  version          = "1.4.5"
  repository       = "https://aws.github.io/eks-charts"
  namespace        = "kube-system"
  create_namespace = true
  cleanup_on_fail  = true

  set {
    name = "serviceAccount.name"
    value = "lb"
  }
}
