locals {
  cluster-config = {
    poc-data-prod = {
      node_types = {
        medium_group = {
          name                   = var.cluster_node_name
          instance_types         = [var.eks_instance_type]
          subnet_ids             = [var.subnet_ids[0]]
          min_size               = var.cluster_min_size
          max_size               = var.cluster_max_size
          desired_size           = var.cluster_desired_size
          vpc_security_group_ids = [
            aws_security_group.small_node_group.id
          ]
          labels = {
            nodegroup-type = "medium"
            node-type      = "medium"
          }
        }
        spot_group_spark = {
          name                   = "spot-group-spark"
          capacity_type          = "SPOT"
          subnet_ids             = [var.subnet_ids[1]]
          instance_types         = ["r5.large"]
          min_size               = var.cluster_spot_min_size
          max_size               = var.cluster_spot_max_size
          desired_size           = var.cluster_spot_desired_size
          vpc_security_group_ids = [
            aws_security_group.small_node_group.id
          ]
          labels = {
            nodegroup-type = "spot-spark"
            node-type      = "spot-spark"
          }
          # Aligned with Lighter executor pod definition
          # https://github.com/exacaster/lighter/blob/master/k8s/executor_pod_template.yaml
          taints = [ 
            {
              key    = "dedicated"
              value  = "spot-spark"
              effect = "NO_SCHEDULE"
            }
          ]
        }
        spot_group_helium = {
          name                   = "spot-group-helium"
          capacity_type          = "SPOT"
          subnet_ids             = [var.subnet_ids[0]]
          instance_types         = ["r5.large"]
          min_size               = var.cluster_spot_min_size
          max_size               = var.cluster_spot_max_size
          desired_size           = var.cluster_spot_desired_size
          vpc_security_group_ids = [
            aws_security_group.small_node_group.id
          ]
          labels = {
            nodegroup-type = "spot-helium"
            node-type      = "spot-helium"
          }
          # Aligned with Lighter executor pod definition
          # https://github.com/exacaster/lighter/blob/master/k8s/executor_pod_template.yaml
          taints = [ 
            {
              key    = "dedicated"
              value  = "spot-helium"
              effect = "NO_SCHEDULE"
            }
          ]
        }
      }
      aws_auth_roles = {
        rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${tolist(data.aws_iam_roles.admin_role.names)[0]}"
        username = "AWSAdministratorAccess:{{SessionName}}"
        groups = [
          "system:masters",
        ]
      }
    }

    oracle-prod = {
      node_types = {
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
      aws_auth_roles = {
        rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${tolist(data.aws_iam_roles.admin_role.names)[0]}"
        username = "AWSAdministratorAccess:{{SessionName}}"
        groups = [
          "view",
        ]
      }
    }

    web-prod = {
      node_types = {
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
      aws_auth_roles = {
        rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${tolist(data.aws_iam_roles.admin_role.names)[0]}"
        username = "AWSAdministratorAccess:{{SessionName}}"
        groups = [
          "view",
        ]
      }
    }

    oracle-sdlc = {
      node_types = {
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
      aws_auth_roles = {
        rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${tolist(data.aws_iam_roles.admin_role.names)[0]}"
        username = "AWSAdministratorAccess:{{SessionName}}"
        groups = [
          "system:masters",
        ]
      }
    }

    web-sdlc = {
      node_types = {
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
      aws_auth_roles = {
        rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${tolist(data.aws_iam_roles.admin_role.names)[0]}"
        username = "AWSAdministratorAccess:{{SessionName}}"
        groups = [
          "system:read-only",
        ]
      }
    }
  }
}