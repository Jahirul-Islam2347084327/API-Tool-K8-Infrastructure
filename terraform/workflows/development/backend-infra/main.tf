terraform {
  backend "s3" {
    bucket = "jahis-devops-directive-state-2026"
    key = "backend-infra/terraform.tfstate"
    region = "us-east-1" # change this to your desired region
    dynamodb_table = "terraform-state-locking"
    encrypt = true
  }
    required_providers {
      aws = {
        source = "hashicorp/aws"
        version = "~> 6.0"
      }
      helm = {
        source = "hashicorp/helm"
        version = "~> 2.12"
      }
    }
}

provider "aws" {
  region = var.region
}

provider "helm" {
    
  kubernetes = {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    }
    }
    }