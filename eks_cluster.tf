module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "18.31.2"

  cluster_name    = local.cluster_name
  cluster_version = "1.22"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_group_defaults = {
    ami_type = "AL2_x86_64"

    attach_cluster_primary_security_group = true

    # Disabling and using externally provided security groups
    create_security_group = false

    # Remove this tag to allow the aws lb to target a single sg using the tag
    # https://github.com/terraform-aws-modules/terraform-aws-eks/issues/2258
    security_group_tags = {
      "kubernetes.io/cluster/${local.cluster_name}" = null
    }
  }

  eks_managed_node_groups = {
    medium_group = {
      name = "small-node-group"

      instance_types = ["t3.medium"]

      min_size     = 1
      max_size     = var.cluster_max_size
      desired_size = var.cluster_desired_size

      pre_bootstrap_user_data = <<-EOT
      EOT

      vpc_security_group_ids = [
        aws_security_group.small_node_group.id
      ]
    }
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.eks.token
  }
}

provider "kubectl" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.eks.token
  load_config_file = false
}


data "aws_eks_cluster" "eks" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "eks" {
  name = module.eks.cluster_id
}

