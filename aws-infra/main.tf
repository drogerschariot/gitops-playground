terraform {
  required_providers {
    aws = {
      version = "~> 5.0"
      source  = "hashicorp/aws"
    }

    kubernetes = {
      version = "~> 2.25"
      source = "hashicorp/kubernetes"
    }

    local = {
      source = "hashicorp/local"
    }
  }

  required_version = ">= 1.1.0"
}

provider "aws" {
  region = local.vpc_information.region
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

locals {
  vpc_information = {
    availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
    public_subnets     = ["10.101.220.0/24", "10.101.221.0/24", "10.101.222.0/24"]
    region             = var.region
    vpc_cidr           = "10.101.0.0/16"
  }
  cluster_name = "${var.name}-eks"
  subnet_availability_zones = tolist(aws_subnet.public[*].availability_zone)
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

  cluster_name    = local.cluster_name
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
      cluster_iam_role_arn = aws_iam_role.karpenter_profile_node_role.arn

      min_size     = var.node_size
      max_size     = var.node_max_size
      desired_size = var.node_size
      tags = {
        "karpenter.sh/discovery" = local.cluster_name
      }
    }
  }

  manage_aws_auth_configmap = true
  aws_auth_roles = [
    # We need to add in the Karpenter node IAM role for nodes launched by Karpenter
    {
      rolearn  = aws_iam_role.karpenter_profile_node_role.arn
      username = "system:node:{{EC2PrivateDNSName}}"
      groups = [
        "system:bootstrappers",
        "system:nodes",
      ]
    },
  ]
}

# resource "aws_ec2_tag" "eks_created_cluster_security_group_tag" {
#   resource_id = module.eks.cluster_security_group_id
#   key         = "karpenter.sh/discovery"
#   value       = module.eks.cluster_name
# }

resource "aws_ec2_tag" "eks_created_security_group_tag2" {
  resource_id = module.eks.node_security_group_id
  key         = "karpenter.sh/discovery"
  value       = module.eks.cluster_name

  depends_on = [ module.eks ]
}

resource "aws_ec2_tag" "eks_created_security_group_tag" {
  resource_id = module.eks.cluster_primary_security_group_id
  key         = "karpenter.sh/discovery"
  value       = module.eks.cluster_name

  depends_on = [ module.eks ]
}

# resource "aws_iam_policy" "instance_profile_policy" {
#   name        = "instance_profile-karpenter-policy"
#   description = "instance profile for karpenter policy"

#   policy = jsonencode({
#     "Version" : "2012-10-17",
#     "Statement" : [
#       {
#         "Effect" : "Allow",
#         "Action" : [
#           "ec2:DescribeInstances",
#           "ec2:DescribeInstanceTypes",
#           "ec2:DescribeRouteTables",
#           "ec2:DescribeSecurityGroups",
#           "ec2:DescribeSubnets",
#           "ec2:DescribeVolumes",
#           "ec2:DescribeVolumesModifications",
#           "ec2:DescribeVpcs",
#           "eks:DescribeCluster"
#         ],
#         "Resource" : "*"
#       },
#       {
#         "Effect" : "Allow",
#         "Action" : [
#           "ec2:AssignPrivateIpAddresses",
#           "ec2:AttachNetworkInterface",
#           "ec2:CreateNetworkInterface",
#           "ec2:DeleteNetworkInterface",
#           "ec2:DescribeInstances",
#           "ec2:DescribeTags",
#           "ec2:DescribeNetworkInterfaces",
#           "ec2:DescribeInstanceTypes",
#           "ec2:DetachNetworkInterface",
#           "ec2:ModifyNetworkInterfaceAttribute",
#           "ec2:UnassignPrivateIpAddresses"
#         ],
#         "Resource" : "*"
#       },
#       {
#         "Effect" : "Allow",
#         "Action" : [
#           "ec2:CreateTags"
#         ],
#         "Resource" : [
#           "arn:aws:ec2:*:*:network-interface/*"
#         ]
#       },
#       {
#         "Effect" : "Allow",
#         "Action" : [
#           "ecr:GetAuthorizationToken",
#           "ecr:BatchCheckLayerAvailability",
#           "ecr:GetDownloadUrlForLayer",
#           "ecr:GetRepositoryPolicy",
#           "ecr:DescribeRepositories",
#           "ecr:ListImages",
#           "ecr:DescribeImages",
#           "ecr:BatchGetImage",
#           "ecr:GetLifecyclePolicy",
#           "ecr:GetLifecyclePolicyPreview",
#           "ecr:ListTagsForResource",
#           "ecr:DescribeImageScanFindings"
#         ],
#         "Resource" : "*"
#       },
#       {
#         "Effect" : "Allow",
#         "Action" : [
#           "ssm:DescribeAssociation",
#           "ssm:GetDeployablePatchSnapshotForInstance",
#           "ssm:GetDocument",
#           "ssm:DescribeDocument",
#           "ssm:GetManifest",
#           "ssm:GetParameter",
#           "ssm:GetParameters",
#           "ssm:ListAssociations",
#           "ssm:ListInstanceAssociations",
#           "ssm:PutInventory",
#           "ssm:PutComplianceItems",
#           "ssm:PutConfigurePackageResult",
#           "ssm:UpdateAssociationStatus",
#           "ssm:UpdateInstanceAssociationStatus",
#           "ssm:UpdateInstanceInformation"
#         ],
#         "Resource" : "*"
#       },
#       {
#         "Effect" : "Allow",
#         "Action" : [
#           "ssmmessages:CreateControlChannel",
#           "ssmmessages:CreateDataChannel",
#           "ssmmessages:OpenControlChannel",
#           "ssmmessages:OpenDataChannel"
#         ],
#         "Resource" : "*"
#       },
#       {
#         "Effect" : "Allow",
#         "Action" : [
#           "ec2messages:AcknowledgeMessage",
#           "ec2messages:DeleteMessage",
#           "ec2messages:FailMessage",
#           "ec2messages:GetEndpoint",
#           "ec2messages:GetMessages",
#           "ec2messages:SendReply"
#         ],
#         "Resource" : "*"
#       }
#     ]
#   })
# }


resource "aws_iam_role" "karpenter_profile_node_role" {
  name = "karpenter-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          "Service" : "ec2.amazonaws.com"
        },
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "karpenter_profile_node_AmazonEKSWorkerNodePolicy" {
  role       = aws_iam_role.karpenter_profile_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "karpenter_profile_node_AmazonEKS_CNI_Policy" {
  role       = aws_iam_role.karpenter_profile_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "karpenter_profile_node_AmazonEC2ContainerRegistryReadOnly" {
  role       = aws_iam_role.karpenter_profile_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "karpenter_profile_node_AmazonSSMManagedInstanceCore" {
  role       = aws_iam_role.karpenter_profile_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Create roles and policies for Karpenter
resource "aws_iam_instance_profile" "karpenter_instance_profile" {
  name = "karpenter-instance-profile"
  role = aws_iam_role.karpenter_profile_node_role.name
}

resource "aws_iam_policy" "karpenter_controller_policy" {
  name        = "karpenter-controller-policy"
  description = "Karpenter controller service account policy"

  policy = <<EOF
{
  "Statement": [
      {
          "Action": [
              "ssm:GetParameter",
              "ec2:DescribeImages",
              "ec2:RunInstances",
              "ec2:DescribeSubnets",
              "ec2:DescribeSecurityGroups",
              "ec2:DescribeLaunchTemplates",
              "ec2:DescribeInstances",
              "ec2:DescribeInstanceTypes",
              "ec2:DescribeInstanceTypeOfferings",
              "ec2:DescribeAvailabilityZones",
              "ec2:DeleteLaunchTemplate",
              "ec2:CreateTags",
              "ec2:CreateLaunchTemplate",
              "ec2:CreateFleet",
              "ec2:DescribeSpotPriceHistory",
              "iam:GetInstanceProfile",
              "iam:CreateInstanceProfile",
              "iam:TagInstanceProfile",
              "iam:AddRoleToInstanceProfile",
              "iam:PassRole",
              "pricing:GetProducts"
          ],
          "Effect": "Allow",
          "Resource": "*",
          "Sid": "Karpenter"
      },
      {
        "Sid": "AllowInterruptionQueueActions",
        "Effect": "Allow",
        "Resource": "${aws_sqs_queue.karpenter_queue.arn}",
        "Action": [
          "sqs:DeleteMessage",
          "sqs:GetQueueUrl",
          "sqs:ReceiveMessage"
        ]
      },
      {
          "Action": "ec2:TerminateInstances",
          "Condition": {
              "StringLike": {
                  "ec2:ResourceTag/karpenter.sh/nodepool": "*"
              }
          },
          "Effect": "Allow",
          "Resource": "*",
          "Sid": "ConditionalEC2Termination"
      },
      {
          "Effect": "Allow",
          "Action": "iam:PassRole",
          "Resource": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/KarpenterNodeRole-${module.eks.cluster_name}",
          "Sid": "PassNodeIAMRole"
      },
      {
          "Effect": "Allow",
          "Action": "eks:DescribeCluster",
          "Resource": "arn:aws:eks:${var.region}:${data.aws_caller_identity.current.account_id}:cluster/${module.eks.cluster_name}",
          "Sid": "EKSClusterEndpointLookup"
      }
  ],
  "Version": "2012-10-17"
}
EOF
}

resource "aws_eks_pod_identity_association" "karpenter_pod_identity" {
  cluster_name    = module.eks.cluster_name
  namespace       = "kube-system"
  service_account = "karpenter"
  role_arn        = aws_iam_role.karpenter_controller_role.arn
}


resource "aws_iam_role" "karpenter_controller_role" {
  name = "karpenter-controller-role"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "pods.eks.amazonaws.com"
            },
            "Action": [
                "sts:AssumeRole",
                "sts:TagSession"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "karpenter_controller_attach" {
  policy_arn = aws_iam_policy.karpenter_controller_policy.arn
  role       = aws_iam_role.karpenter_controller_role.name
}

# resource "aws_iam_role_policy_attachment" "karpenter-attach" {
#   role       = aws_iam_role.karpenter_role.name
#   policy_arn = aws_iam_policy.karpenter_controller.arn
# }

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

## SQS for Karpenter
resource "aws_sqs_queue" "karpenter_queue" {
  name                      = module.eks.cluster_name
  message_retention_seconds = 600
  sqs_managed_sse_enabled   = true

  tags = {
    Environment = "production"
  }
}

data "aws_iam_policy_document" "karpenter_queue_policy" {
  statement {
    sid    = "First"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com", "sqs.amazonaws.com"]
    }

    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.karpenter_queue.arn]
  }
}

resource "aws_sqs_queue_policy" "karpenter_queue_policy" {
  queue_url = aws_sqs_queue.karpenter_queue.id
  policy    = data.aws_iam_policy_document.karpenter_queue_policy.json
}

resource "aws_cloudwatch_event_rule" "ScheduledChangeRule" {
  name        = "KarpenterInterruptionQueueTarget"
  description = "AWS Health Event Rule"

  event_pattern = jsonencode({
    source      = ["aws.health"],
    detail_type = ["AWS Health Event"]
  })
}

resource "aws_cloudwatch_event_target" "ScheduledChangeRule" {
  rule = aws_cloudwatch_event_rule.ScheduledChangeRule.name
  arn  = aws_sqs_queue.karpenter_queue.arn
}

resource "aws_cloudwatch_event_rule" "KarpenterInterruptionQueueTarget" {
  name        = "KarpenterInterruptionQueueTarget"
  description = "EC2 Spot Instance Interruption Warning"

  event_pattern = jsonencode({
    source      = ["aws.ec2"],
    detail_type = ["EC2 Spot Instance Interruption Warning"]
  })
}

resource "aws_cloudwatch_event_target" "KarpenterInterruptionQueueTarget" {
  rule = aws_cloudwatch_event_rule.KarpenterInterruptionQueueTarget.name
  arn  = aws_sqs_queue.karpenter_queue.arn
}

resource "aws_cloudwatch_event_rule" "RebalanceRule" {
  name        = "RebalanceRule"
  description = "EC2 Instance Rebalance Recommendation"

  event_pattern = jsonencode({
    source      = ["aws.ec2"],
    detail_type = ["EC2 Instance Rebalance Recommendation"]
  })
}

resource "aws_cloudwatch_event_target" "RebalanceRule" {
  rule = aws_cloudwatch_event_rule.RebalanceRule.name
  arn  = aws_sqs_queue.karpenter_queue.arn
}

resource "aws_cloudwatch_event_rule" "InstanceStateChangeRule" {
  name        = "InstanceStateChangeRule"
  description = "EC2 Instance State-change Notification"

  event_pattern = jsonencode({
    source      = ["aws.ec2"],
    detail_type = ["EC2 Instance State-change Notification"]
  })
}

resource "aws_cloudwatch_event_target" "InstanceStateChangeRule" {
  rule = aws_cloudwatch_event_rule.InstanceStateChangeRule.name
  arn  = aws_sqs_queue.karpenter_queue.arn
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

### Karpenter values
# resource "local_file" "karpenter_values" {
#   content  = <<-EOT
#         controller:
#           logLevel: "debug"	
#         serviceAccount:
#           annotations:  
#                 eks.amazonaws.com/role-arn: ${aws_iam_role.karpenter_role.arn}
#         clusterName: "${module.eks.cluster_name}" # it is has to be the exact same name of the cluster
#         clusterEndpoint: ${module.eks.cluster_endpoint}
        
#         # aws configuration
        
#         aws:
#           # give the instance username we've created before. it already got the role inside.
#           defaultInstanceProfile: ${aws_iam_instance_profile.karpenter.name}
#     EOT

#   filename = "values.yaml"
# }

# resource "local_file" "karpenter_provisioner" {
#   filename = "provisioner-jenkins.yaml"
#   content  = <<EOT
# apiVersion: karpenter.sh/v1alpha5
# kind: Provisioner
# metadata:
#   name: karpenter-node-group-jenkins
#   namespace: karpenter
# spec:
#   provider:
#     securityGroupSelector:
#       Name: "${module.eks.cluster_security_group_id}" # take the security group you are using with the cluster
#     subnetSelector: 
#       Name: "*${var.name}-public-subnet*" # take the subnet you are using with the cluster
#   labels:
#     cluster: "${module.eks.cluster_name}"
#     name: karpter-provisioner-jenkins
#     created-by: "karpenter"   
#   requirements:
#   - key: "node.kubernetes.io/instance-type"
#     operator: In
#     values: ["t3.medium", "t3.large", "t3.xlarge"]
#   - key: "topology.kubernetes.io/zone"
#     operator: In
#     values: [${join(", ", local.subnet_availability_zones)}]
#   - key: "kubernetes.io/arch"
#     operator: In
#     values: ["amd64"]
#   - key: "karpenter.sh/capacity-type" 
#     operator: In
#     values: ["on-demand", "spot"]
#     # this is an example for how we can use the label from above
#   - key: created-by
#     operator: In
#     values: ["karpenter"]
#   # limit our karpenter node expand. it will not pass those values.
#   limits:
#     resources:
#       cpu: "20"
#       memory: 64Gi
# EOT
# }

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
    "kubernetes.io/cluster/${var.name}-eks" = "shared",
    "karpenter.sh/discovery" = local.cluster_name
  }
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

# Outputs
output "node_security_group_id" {
  value = module.eks.node_security_group_id
}

output "cluster_primary_security_group_id" {
  value = module.eks.cluster_primary_security_group_id
}
