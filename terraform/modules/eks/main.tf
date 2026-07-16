module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.10.1"

  name               = "production-eks"
  kubernetes_version = "1.33"

  addons = {
    coredns = {}
    eks-pod-identity-agent = {
      before_compute = true
    }
    kube-proxy = {}
    vpc-cni = {
      before_compute = true
    }
  }


  endpoint_public_access = true


  enable_cluster_creator_admin_permissions = true

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.private_subnets


  eks_managed_node_groups = {
    example = {

      instance_types = ["t3.small"]

      min_size     = 3
      max_size     = 6
      desired_size = 3
    }
  }

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}