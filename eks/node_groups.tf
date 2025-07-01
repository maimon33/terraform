# EKS Node Groups
resource "aws_eks_node_group" "main" {
  for_each = var.node_groups

  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.cluster_name}-${each.key}"
  node_role_arn   = aws_iam_role.eks_node.arn
  subnet_ids      = each.value.subnet_type == "private" ? var.private_subnet_ids : var.public_subnet_ids
  ami_type        = "AL2023_x86_64_STANDARD"

  instance_types = each.value.instance_types
  capacity_type  = each.value.capacity_type

  scaling_config {
    desired_size = each.value.desired_size
    max_size     = each.value.max_size
    min_size     = each.value.min_size
  }

  labels = merge(each.value.labels, {
    nodegroup = each.key
  })

  dynamic "taint" {
    for_each = each.value.taints
    content {
      key    = taint.value.key
      value  = taint.value.value
      effect = taint.value.effect
    }
  }

  tags = merge(var.default_tags, {
    Name = "${var.cluster_name}-${each.key}-nodegroup"
  })

  depends_on = [
    aws_iam_role_policy_attachment.eks_node_policies
  ]
} 