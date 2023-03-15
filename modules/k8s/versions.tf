terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
    aws = {
      source = "hashicorp/aws"
       configuration_aliases = [ aws.virginia ]
    }
  }
}
