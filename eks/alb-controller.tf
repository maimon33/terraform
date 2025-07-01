# AWS Load Balancer Controller deployment using Helm
resource "helm_release" "alb_controller" {
  count = var.enable_alb_controller ? 1 : 0

  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.7.1"

  replace      = true
  force_update = true
  wait         = true
  wait_for_jobs = true

  set {
    name  = "clusterName"
    value = data.aws_eks_cluster.main.name
  }

  set {
    name  = "region"
    value = var.aws_region
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "vpcId"
    value = var.vpc_id
  }

  depends_on = [
    data.aws_eks_cluster.main,
    aws_eks_node_group.main,
    aws_eks_addon.coredns,
    aws_eks_addon.kube_proxy,
    aws_eks_addon.vpc_cni,
    aws_iam_role.alb_controller,
    aws_iam_role_policy_attachment.alb_controller,
    kubernetes_service_account.alb_controller
  ]

  timeout = 900
}

# Create the service account for ALB Controller
resource "kubernetes_service_account" "alb_controller" {
  count = var.enable_alb_controller ? 1 : 0

  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.alb_controller[0].arn
    }
  }

  depends_on = [
    data.aws_eks_cluster.main,
    aws_eks_node_group.main,
    aws_iam_role.alb_controller
  ]
} 