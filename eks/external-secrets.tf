# External Secrets Operator deployment using Helm
resource "helm_release" "external_secrets" {
  count = var.enable_external_secrets ? 1 : 0

  name       = "external-secrets"
  repository = "https://charts.external-secrets.io"
  chart      = "external-secrets"
  namespace  = "default"
  version    = "0.9.5"

  create_namespace = false
  replace          = true
  force_update     = true
  wait             = true
  wait_for_jobs    = true

  set {
    name  = "installCRDs"
    value = "true"
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = "external-secrets"
  }

  set {
    name  = "webhook.create"
    value = "false"
  }

  set {
    name  = "certController.create"
    value = "false"
  }

  set {
    name  = "extraEnv[0].name"
    value = "AWS_REGION"
  }

  set {
    name  = "extraEnv[0].value"
    value = var.aws_region
  }

  depends_on = [
    data.aws_eks_cluster.main,
    aws_eks_node_group.main,
    aws_eks_addon.coredns,
    aws_eks_addon.kube_proxy,
    aws_eks_addon.vpc_cni,
    aws_iam_role.external_secrets,
    aws_iam_role_policy.external_secrets,
    kubernetes_service_account.external_secrets
  ]

  timeout = 900
}

# Create the service account for External Secrets Operator
resource "kubernetes_service_account" "external_secrets" {
  count = var.enable_external_secrets ? 1 : 0

  metadata {
    name      = "external-secrets"
    namespace = "default"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.external_secrets[0].arn
    }
  }

  depends_on = [
    data.aws_eks_cluster.main,
    aws_eks_node_group.main,
    aws_iam_role.external_secrets
  ]
} 