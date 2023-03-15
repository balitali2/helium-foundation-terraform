locals {
  auth_config = {
    rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${tolist(data.aws_iam_roles.admin_role.names)[0]}"
    username = "AWSAdministratorAccess:{{SessionName}}"
    groups = [
      "system:masters",
    ]
  }
  karpenter_config = {
    rolearn  = module.karpenter.role_arn
    username = "system:node:{{EC2PrivateDNSName}}"
    groups = [
      "system:bootstrappers",
      "system:nodes",
    ]
  }
}