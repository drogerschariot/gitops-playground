terraform {
  required_providers {
    aws = {
      version = "~> 4.50.0"
      source  = "hashicorp/aws"
    }
  }

  required_version = ">= 1.1.0"
}

provider "aws" {
  region = local.vpc_information.region
}

locals {
  vpc_information = {
    availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
    public_subnets     = ["10.101.220.0/24", "10.101.221.0/24", "10.101.222.0/24"]
    region             = var.region
    vpc_cidr           = "10.101.0.0/16"
  }
}

data "aws_caller_identity" "current" {}

data "aws_subnets" "public" {
  filter {
    name = "tag:Name"
    values = [ "${var.name}-public-subnet" ]
  }

  depends_on = [
    aws_subnet.public
  ]
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.0.4"

  cluster_name    = "${var.name}-eks"
  cluster_version = var.cluster_version

  vpc_id     = aws_vpc.vpc.id
  subnet_ids = data.aws_subnets.public.ids
  cluster_endpoint_public_access = true

  eks_managed_node_group_defaults = {
    ami_type = "AL2_x86_64"
  }

  cluster_addons = {
    coredns = {
      resolve_conflicts = "OVERWRITE"
    }
    kube-proxy = {}
    vpc-cni = {
      resolve_conflicts = "OVERWRITE"
    }
  }

  create_kms_key = false
  cluster_encryption_config = {
    resources        = ["secrets"]
    provider_key_arn = aws_kms_key.my-eks-cluster.arn
  }

  eks_managed_node_groups = {
    one = {
      name = "default_node_group"

      instance_types       = [var.node_type]
      cluster_iam_role_arn = aws_iam_role.node_role.arn

      min_size     = var.node_size
      max_size     = var.node_size
      desired_size = var.node_size
    }
  }
}

resource "aws_iam_role" "eks_cluster_role" {
  name = "eks-cluster-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

resource "aws_kms_key" "my-eks-cluster" {
  description = "my-eks-cluster"
}

resource "aws_iam_role" "node_role" {
  name = "${var.name}-node-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "node_policy" {
  role = aws_iam_role.node_role.name

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ecr:BatchCheckLayerAvailability",
                "ecr:BatchGetImage",
                "ecr:GetDownloadUrlForLayer",
                "ecr:GetAuthorizationToken"
            ],
            "Resource": "*"
        }
    ]
}
POLICY
}

resource "aws_iam_role_policy" "node_pod_identity_policy" {
  role = aws_iam_role.node_role.name

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": ["eks-auth:AssumeRoleForPodIdentity"],
            "Resource": "*"
        }
    ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "nodes_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node_role.name
}

resource "aws_iam_role_policy_attachment" "nodes_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node_role.name
}

resource "aws_iam_role_policy_attachment" "nodes_read_only" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node_role.name
}

# data "tls_certificate" "eks" {
#   url = module.eks.cluster_oidc_issuer_url
# }

# resource "aws_iam_openid_connect_provider" "eks" {
#   client_id_list  = ["sts.amazonaws.com"]
#   thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
#   url             = module.eks.cluster_oidc_issuer_url
# }

data "aws_iam_policy_document" "csi" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${module.eks.oidc_provider}:sub"
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
    }

    principals {
      identifiers = [module.eks.oidc_provider_arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "eks_ebs_csi_driver" {
  assume_role_policy = data.aws_iam_policy_document.csi.json
  name               = "eks-ebs-csi-driver"
}

resource "aws_iam_role_policy_attachment" "amazon_ebs_csi_driver" {
  role       = aws_iam_role.eks_ebs_csi_driver.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

resource "aws_eks_addon" "csi_driver" {
  cluster_name             = module.eks.cluster_name
  addon_name               = "aws-ebs-csi-driver"
  addon_version            = "v1.24.0-eksbuild.1"
  service_account_role_arn = aws_iam_role.eks_ebs_csi_driver.arn

  depends_on = [
    module.eks
  ]
}

resource "aws_eks_addon" "eks_pod_identity_agent" {
  cluster_name             = module.eks.cluster_name
  addon_name               = "eks-pod-identity-agent"
  addon_version            = "v1.0.0-eksbuild.1"

  depends_on = [
    module.eks
  ]
}

### VPC

resource "aws_vpc" "vpc" {
  cidr_block                       = local.vpc_information.vpc_cidr
  enable_dns_support               = true
  enable_dns_hostnames             = true
  assign_generated_ipv6_cidr_block = false
}

resource "aws_internet_gateway" "ig" {
  vpc_id = aws_vpc.vpc.id
}

## Public Subnet

resource "aws_subnet" "public" {
  count = length(local.vpc_information.public_subnets)

  assign_ipv6_address_on_creation = false
  availability_zone               = local.vpc_information.availability_zones[count.index]
  cidr_block                      = local.vpc_information.public_subnets[count.index]
  map_public_ip_on_launch         = true
  vpc_id                          = aws_vpc.vpc.id

  tags = { 
    Name = "${var.name}-public-subnet",
    "kubernetes.io/role/elb" = "1",
    "kubernetes.io/cluster/${var.name}-eks" = "shared"}
}

resource "aws_route_table" "public" {
  count = length(local.vpc_information.public_subnets)

  vpc_id = aws_vpc.vpc.id
}

resource "aws_route" "ipv4_public_internet_traffic" {
  count = length(local.vpc_information.public_subnets)

  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.ig.id
  route_table_id         = aws_route_table.public[count.index].id
}

resource "aws_route_table_association" "public" {
  count = length(local.vpc_information.public_subnets)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[count.index].id
}

resource "aws_network_acl" "public" {
  vpc_id     = aws_vpc.vpc.id
  subnet_ids = aws_subnet.public.*.id

  lifecycle {
    create_before_destroy = true
  }

  ###################
  # Ingress section #
  ###################

  # Allow all IPv4 Traffic
  ingress {
    rule_no    = 100
    protocol   = "-1"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  # Allow all IPv6 Traffic
  ingress {
    rule_no         = 101
    protocol        = "-1"
    action          = "allow"
    ipv6_cidr_block = "::/0"
    from_port       = 0
    to_port         = 0
  }

  ##################
  # Egress section #
  ##################

  # HTTP IPv4 Outbound
  egress {
    rule_no    = 100
    protocol   = "-1"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  # HTTP IPv6 Outbound
  egress {
    rule_no         = 101
    protocol        = "-1"
    action          = "allow"
    ipv6_cidr_block = "::/0"
    from_port       = 0
    to_port         = 0
  }
}
