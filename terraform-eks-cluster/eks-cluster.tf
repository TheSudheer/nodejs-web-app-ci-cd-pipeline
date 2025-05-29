module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.17.2"

  # Basic Cluster Information
  cluster_name    = "myapp-eks-cluster"
  cluster_version = "1.28"

  # Networking configuration: Worker nodes will be placed in the private subnets
  subnet_ids = module.vpc.private_subnets
  vpc_id     = module.vpc.vpc_id
  cluster_endpoint_public_access = true

  # Tags for the cluster (can be used for classification or filtering)
  tags = {
    environment = "development"
    application = "myapp"
  }

  # EKS Managed Node Groups Configuration
  eks_managed_node_groups = {
    dev = {
      min_size     = 1
      max_size     = 3
      desired_size = 3
      instance_types = ["t2.large"]
    }
  }
}
