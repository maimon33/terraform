# EKS Cluster outputs
output "cluster_id" {
  description = "EKS cluster ID"
  value       = aws_eks_cluster.main.id
}

output "cluster_arn" {
  description = "EKS cluster ARN"
  value       = aws_eks_cluster.main.arn
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_version" {
  description = "EKS cluster version"
  value       = aws_eks_cluster.main.version
}

output "cluster_oidc_issuer_url" {
  description = "EKS cluster OIDC issuer URL"
  value       = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

output "cluster_oidc_provider_arn" {
  description = "EKS cluster OIDC provider ARN"
  value       = aws_iam_openid_connect_provider.main.arn
}

# Node Groups outputs
output "node_groups" {
  description = "EKS node groups"
  value = {
    for name, node_group in aws_eks_node_group.main : name => {
      id             = node_group.id
      arn            = node_group.arn
      node_role_arn  = node_group.node_role_arn
      status         = node_group.status
    }
  }
}

# IAM Role outputs
output "ebs_csi_role_arn" {
  description = "EBS CSI Driver IAM role ARN"
  value       = var.enable_ebs_csi ? aws_iam_role.ebs_csi[0].arn : null
}

output "alb_controller_role_arn" {
  description = "ALB Controller IAM role ARN"
  value       = var.enable_alb_controller ? aws_iam_role.alb_controller[0].arn : null
}

output "external_secrets_role_arn" {
  description = "External Secrets IAM role ARN"
  value       = var.enable_external_secrets ? aws_iam_role.external_secrets[0].arn : null
}

# AWS Secrets Manager outputs
output "cluster_secrets_arn" {
  description = "ARN of the cluster secrets"
  value       = aws_secretsmanager_secret.cluster_secrets.arn
}

output "cluster_secrets_name" {
  description = "Name of the cluster secrets"
  value       = aws_secretsmanager_secret.cluster_secrets.name
}

output "force_delete_secret_arn" {
  description = "ARN of the app secrets"
  value       = aws_secretsmanager_secret.app_secrets.arn
}

output "force_delete_secret_name" {
  description = "Name of the app secrets"
  value       = aws_secretsmanager_secret.app_secrets.name
}

output "dummy_secret_key" {
  description = "Dummy secret key for demonstration"
  value       = "dummy_secret"
}

# Kubeconfig command
output "kubeconfig_command" {
  description = "Command to configure kubeconfig"
  value       = "aws eks update-kubeconfig --name ${var.cluster_name} --region ${var.aws_region}"
}

# Kubectl context deletion commands
output "kubectl_context_deletion_commands" {
  description = "Commands to manually delete kubectl context if needed"
  value = {
    delete_context = "kubectl config delete-context ${var.cluster_name}"
    delete_cluster = "kubectl config delete-cluster ${var.cluster_name}"
    delete_user    = "kubectl config delete-user ${var.cluster_name}"
  }
}