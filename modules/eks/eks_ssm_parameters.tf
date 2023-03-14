resource "aws_ssm_parameter" "is_karpenter_deployed" {
  name        = "/eks/karpenter/is_deployed"
  description = "Is AWS infrastructure for Karpenter deployed?"
  type        = "String"
  value       = "${var.karpenter_autoscaling}"
}

resource "aws_ssm_parameter" "irsa_arn" {
  count = var.karpenter_autoscaling ? 1 : 0

  name        = "/eks/karpenter/irsa_arn"
  description = "ARN of IRSA required for Karpenter"
  type        = "String"
  value       = "${module.karpenter.irsa_arn}"
}

resource "aws_ssm_parameter" "instance_profile_name" {
  count = var.karpenter_autoscaling ? 1 : 0

  name        = "/eks/karpenter/instance_profile_name"
  description = "Instance profile name for Karpenter"
  type        = "String"
  value       = "${module.karpenter.instance_profile_name}"
}

resource "aws_ssm_parameter" "queue_name" {
  count = var.karpenter_autoscaling ? 1 : 0

  name        = "/eks/karpenter/queue_name"
  description = "SQS name for Karpenter"
  type        = "String"
  value       = "${module.karpenter.queue_name}"
}