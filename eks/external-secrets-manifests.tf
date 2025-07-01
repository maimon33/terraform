# External Secrets configuration using Terraform null_resource
resource "null_resource" "external_secrets_config" {
  depends_on = [
    helm_release.external_secrets,
    aws_secretsmanager_secret_version.cluster_secrets
  ]

  triggers = {
    external_secrets_version = helm_release.external_secrets[0].version
    cluster_secrets_version  = aws_secretsmanager_secret_version.cluster_secrets.id
  }

  provisioner "local-exec" {
    command = <<-EOT
      cat <<EOF | kubectl apply -f -
      apiVersion: external-secrets.io/v1beta1
      kind: SecretStore
      metadata:
        name: aws-secretsmanager
        namespace: default
      spec:
        provider:
          aws:
            service: SecretsManager
            region: ${data.aws_region.current.name}
            auth:
              jwt:
                serviceAccountRef:
                  name: external-secrets
                  namespace: default
      ---
      apiVersion: external-secrets.io/v1beta1
      kind: ExternalSecret
      metadata:
        name: default-secrets
        namespace: default
      spec:
        refreshInterval: 1h
        secretStoreRef:
          name: aws-secretsmanager
          kind: SecretStore
        target:
          name: default-secrets
        data:
        - secretKey: dummy_secret
          remoteRef:
            key: ${aws_secretsmanager_secret.cluster_secrets.name}
            property: dummy_secret
      EOF
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = "kubectl delete externalsecret default-secrets -n default --ignore-not-found=true"
  }
} 