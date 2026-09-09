terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# Data source to fetch current AWS account details
data "aws_caller_identity" "current" {}

# VPC and Networking Configuration
resource "aws_vpc" "mp_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name                                        = "mp-vpc"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

resource "aws_subnet" "mp_subnet_a" {
  vpc_id                  = aws_vpc.mp_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = true

  tags = {
    Name                                        = "mp-subnet-a"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

resource "aws_subnet" "mp_subnet_b" {
  vpc_id                  = aws_vpc.mp_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "${var.region}b"
  map_public_ip_on_launch = true

  tags = {
    Name                                        = "mp-subnet-b"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

resource "aws_internet_gateway" "mp_igw" {
  vpc_id = aws_vpc.mp_vpc.id

  tags = {
    Name = "mp-igw"
  }
}

resource "aws_route_table" "mp_route_table" {
  vpc_id = aws_vpc.mp_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.mp_igw.id
  }

  tags = {
    Name = "mp-route-table"
  }
}

resource "aws_route_table_association" "mp_rta_a" {
  subnet_id      = aws_subnet.mp_subnet_a.id
  route_table_id = aws_route_table.mp_route_table.id
}

resource "aws_route_table_association" "mp_rta_b" {
  subnet_id      = aws_subnet.mp_subnet_b.id
  route_table_id = aws_route_table.mp_route_table.id
}

# ECR Repositories for Frontend and Backend
resource "aws_ecr_repository" "mp_frontend" {
  name                 = "mp-frontend"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Environment = var.environment
    Application = "movie-picture-frontend"
  }
}

resource "aws_ecr_repository" "mp_backend" {
  name                 = "mp-backend"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Environment = var.environment
    Application = "movie-picture-backend"
  }
}

# IAM Role for EKS Cluster
resource "aws_iam_role" "eks_cluster_role" {
  name = "mp-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

# EKS Cluster
resource "aws_eks_cluster" "mp_cluster" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids = [
      aws_subnet.mp_subnet_a.id,
      aws_subnet.mp_subnet_b.id
    ]
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_AmazonEKSClusterPolicy
  ]

  tags = {
    Environment = var.environment
  }
}

# IAM Role for EKS Node Group
resource "aws_iam_role" "eks_nodes_role" {
  name = "mp-eks-nodes-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_nodes_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_nodes_role.name
}

resource "aws_iam_role_policy_attachment" "eks_nodes_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_nodes_role.name
}

resource "aws_iam_role_policy_attachment" "eks_nodes_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_nodes_role.name
}

# EKS Node Group
resource "aws_eks_node_group" "mp_node_group" {
  cluster_name    = aws_eks_cluster.mp_cluster.name
  node_group_name = "mp-node-group"
  node_role_arn   = aws_iam_role.eks_nodes_role.arn
  subnet_ids      = [aws_subnet.mp_subnet_a.id, aws_subnet.mp_subnet_b.id]

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  instance_types = ["t3.medium"]

  depends_on = [
    aws_iam_role_policy_attachment.eks_nodes_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.eks_nodes_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.eks_nodes_AmazonEC2ContainerRegistryReadOnly,
  ]
}

# IAM User for GitHub Actions CI/CD
resource "aws_iam_user" "github_action_user" {
  name = "github-action-user"

  tags = {
    Purpose = "GitHub Actions CI/CD Pipeline Automation"
  }
}

# Policy for GitHub Actions user (ECR, EKS, and IAM get user)
resource "aws_iam_policy" "github_actions_policy" {
  name        = "github-action-user-policy"
  description = "Permissions required by GitHub Actions for ECR and EKS operations"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "IAMGetUser"
        Effect = "Allow"
        Action = [
          "iam:GetUser"
        ]
        Resource = aws_iam_user.github_action_user.arn
      },
      {
        Sid    = "ECRAuth"
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      },
      {
        Sid    = "ECRAccess"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetRepositoryPolicy",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:DescribeImages",
          "ecr:BatchGetImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage"
        ]
        Resource = [
          aws_ecr_repository.mp_frontend.arn,
          aws_ecr_repository.mp_backend.arn
        ]
      },
      {
        Sid    = "EKSClusterAccess"
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "github_actions_attach" {
  user       = aws_iam_user.github_action_user.name
  policy_arn = aws_iam_policy.github_actions_policy.arn
}
