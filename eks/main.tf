# This file is intentionally empty
# All resources have been moved to separate files for better organization:
# - cluster.tf: EKS cluster and OIDC provider
# - iam.tf: All IAM roles and policies
# - node_groups.tf: EKS node groups
# - addons.tf: EKS addons
# - data.tf: Data sources
# - variables.tf: Variable definitions
# - outputs.tf: Output values
# - providers.tf: Provider configurations
# - versions.tf: Terraform and provider versions

# Delete kubectl context when destroying resources
resource "null_resource" "delete_kubectl_context" {
  triggers = {
    cluster_name = aws_eks_cluster.main.name
    cluster_arn  = aws_eks_cluster.main.arn
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      echo "Cleaning up kubectl context for cluster: ${self.triggers.cluster_name}"
      
      # Delete context
      kubectl config delete-context ${self.triggers.cluster_name} 2>/dev/null || echo "Context ${self.triggers.cluster_name} not found or already deleted"
      
      # Delete cluster
      kubectl config delete-cluster ${self.triggers.cluster_name} 2>/dev/null || echo "Cluster ${self.triggers.cluster_name} not found or already deleted"
      
      # Delete user
      kubectl config delete-user ${self.triggers.cluster_name} 2>/dev/null || echo "User ${self.triggers.cluster_name} not found or already deleted"
      
      echo "Kubectl context cleanup completed for cluster: ${self.triggers.cluster_name}"
    EOT
  }

  depends_on = [
    aws_eks_cluster.main
  ]
}