output "region" {
  description = "AWS region"
  value       = var.region
}

output "cluster_name" {
  description = "EKS Cluster Name"
  value       = aws_eks_cluster.mp_cluster.name
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = aws_eks_cluster.mp_cluster.endpoint
}

output "ecr_frontend_repository_url" {
  description = "Repository URL for Frontend ECR"
  value       = aws_ecr_repository.mp_frontend.repository_url
}

output "ecr_backend_repository_url" {
  description = "Repository URL for Backend ECR"
  value       = aws_ecr_repository.mp_backend.repository_url
}

output "github_action_user_name" {
  description = "IAM user for GitHub Actions"
  value       = aws_iam_user.github_action_user.name
}

output "github_action_user_arn" {
  description = "IAM user ARN for GitHub Actions"
  value       = aws_iam_user.github_action_user.arn
}
