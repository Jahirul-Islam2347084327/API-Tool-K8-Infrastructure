terraform {
  backend "s3" {
    bucket = "jahis-devops-directive-state-2026"
    key = "eks-backend/terraform.tfstate"
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

    module "eks" {
      source = "../../../modules/eks"
      vpc-id = module.network.vpc_id
      private-subnets = module.network.private_subnets
    }

    module "k8-apps" {
      source = "../../../modules/k8-apps"
      external-dns-iam = module.iam.external-iam-arn
      cert-manager-iam = module.iam.cert-iam-arn
    }

    module "network" {
      source = "../../../modules/networking"
    }

    module "iam" {
      source = "../../../modules/iam"
      cluster-oidc-issuer-url = module.eks.cluster_oidc_issuer_url
      oidc-provider-arn = module.eks.oidc_provider_arn
    }

    module "ecr" {
      source = "../../../modules/ecr"
    }
