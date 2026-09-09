variable "region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "mp-cluster"
}

variable "environment" {
  description = "Deployment environment name"
  type        = string
  default     = "production"
}
