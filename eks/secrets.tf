# Single AWS Secrets Manager secret for the entire cluster
resource "aws_secretsmanager_secret" "cluster_secrets" {
  name        = "${var.cluster_name}/default"
  description = "Secrets for ${var.cluster_name} cluster in default namespace"
  
  # Force immediate deletion without recovery period
  recovery_window_in_days = 0
  
  tags = {
    Name        = "${var.cluster_name}-default-secrets"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_secretsmanager_secret_version" "cluster_secrets" {
  secret_id = aws_secretsmanager_secret.cluster_secrets.id
  secret_string = jsonencode({
    # Dummy secret to demonstrate External Secrets Operator functionality
    dummy_secret = "dummy_value_123"
  })
}

# AWS Secrets Manager secret
resource "aws_secretsmanager_secret" "app_secrets" {
  name        = "${var.cluster_name}/app-secrets"
  description = "Application secrets for ${var.cluster_name} cluster"
  
  # Force immediate deletion without recovery period
  recovery_window_in_days = 0
  
  tags = {
    Name        = "${var.cluster_name}-app-secrets"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_secretsmanager_secret_version" "app_secrets" {
  secret_id = aws_secretsmanager_secret.app_secrets.id
  secret_string = jsonencode({
    # Example application secrets
    api_key     = "example_api_key_123"
    db_password = "example_db_password_456"
    jwt_secret  = "example_jwt_secret_789"
  })
} 