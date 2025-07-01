data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

# Expose account ID for use in scripts
locals {
  account_id = data.aws_caller_identity.current.account_id
}

# Data sources for subnets to validate tags
data "aws_subnet" "private" {
  for_each = toset(var.private_subnet_ids)
  id       = each.value
}

data "aws_subnet" "public" {
  for_each = toset(var.public_subnet_ids)
  id       = each.value
}

# Validation for ALB Controller subnet tags
locals {
  # Get subnet tag values safely
  private_subnet_internal_elb_tags = {
    for subnet_id, subnet in data.aws_subnet.private :
    subnet_id => lookup(subnet.tags, "kubernetes.io/role/internal-elb", "missing")
  }
  
  public_subnet_elb_tags = {
    for subnet_id, subnet in data.aws_subnet.public :
    subnet_id => lookup(subnet.tags, "kubernetes.io/role/elb", "missing")
  }
  
  all_subnet_cluster_tags = {
    for subnet_id, subnet in merge(data.aws_subnet.private, data.aws_subnet.public) :
    subnet_id => lookup(subnet.tags, "kubernetes.io/cluster/${var.cluster_name}", "missing")
  }
  
  # Validation results
  private_subnet_tags_valid = alltrue([
    for subnet_id, tag_value in local.private_subnet_internal_elb_tags :
    tag_value == "1"
  ])
  
  public_subnet_tags_valid = alltrue([
    for subnet_id, tag_value in local.public_subnet_elb_tags :
    tag_value == "1"
  ])
  
  all_subnet_cluster_tags_valid = alltrue([
    for subnet_id, tag_value in local.all_subnet_cluster_tags :
    tag_value == "shared"
  ])
  
  # Detailed error messages
  private_subnet_errors = [
    for subnet_id, tag_value in local.private_subnet_internal_elb_tags :
    "  - ${subnet_id}: kubernetes.io/role/internal-elb = '${tag_value}' (should be '1')"
    if tag_value != "1"
  ]
  
  public_subnet_errors = [
    for subnet_id, tag_value in local.public_subnet_elb_tags :
    "  - ${subnet_id}: kubernetes.io/role/elb = '${tag_value}' (should be '1')"
    if tag_value != "1"
  ]
  
  cluster_tag_errors = [
    for subnet_id, tag_value in local.all_subnet_cluster_tags :
    "  - ${subnet_id}: kubernetes.io/cluster/${var.cluster_name} = '${tag_value}' (should be 'shared')"
    if tag_value != "shared"
  ]
}

# Validation checks with detailed error messages
check "alb_controller_private_subnet_tags" {
  assert {
    condition = local.private_subnet_tags_valid
    error_message = <<-EOT
Private subnets are missing required tags for ALB Controller internal load balancers:

${join("\n", local.private_subnet_errors)}

To fix this, run the following AWS CLI commands:

${join("\n", [
  for subnet_id in keys(local.private_subnet_internal_elb_tags) :
  "aws ec2 create-tags --resources ${subnet_id} --tags Key=kubernetes.io/role/internal-elb,Value=1"
])}

Or use the helper script:
./scripts/tag-subnets.sh "${var.cluster_name}" "${join(" ", var.private_subnet_ids)}" "${join(" ", var.public_subnet_ids)}"
EOT
  }
}

check "alb_controller_public_subnet_tags" {
  assert {
    condition = local.public_subnet_tags_valid
    error_message = <<-EOT
Public subnets are missing required tags for ALB Controller external load balancers:

${join("\n", local.public_subnet_errors)}

To fix this, run the following AWS CLI commands:

${join("\n", [
  for subnet_id in keys(local.public_subnet_elb_tags) :
  "aws ec2 create-tags --resources ${subnet_id} --tags Key=kubernetes.io/role/elb,Value=1"
])}

Or use the helper script:
./scripts/tag-subnets.sh "${var.cluster_name}" "${join(" ", var.private_subnet_ids)}" "${join(" ", var.public_subnet_ids)}"
EOT
  }
}

check "alb_controller_cluster_tags" {
  assert {
    condition = local.all_subnet_cluster_tags_valid
    error_message = <<-EOT
All subnets are missing required cluster tags for ALB Controller:

${join("\n", local.cluster_tag_errors)}

To fix this, run the following AWS CLI commands:

${join("\n", [
  for subnet_id in keys(local.all_subnet_cluster_tags) :
  "aws ec2 create-tags --resources ${subnet_id} --tags Key=kubernetes.io/cluster/${var.cluster_name},Value=shared"
])}

Or use the helper script:
./scripts/tag-subnets.sh "${var.cluster_name}" "${join(" ", var.private_subnet_ids)}" "${join(" ", var.public_subnet_ids)}"
EOT
  }
}

data "aws_iam_policy_document" "eks_cluster_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "eks_node_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "alb_controller_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.main.arn]
    }
    actions = ["sts:AssumeRoleWithWebIdentity"]
    condition {
      test     = "StringEquals"
      variable = "${replace(aws_eks_cluster.main.identity[0].oidc[0].issuer, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
    }
  }
}

data "aws_iam_policy_document" "external_secrets_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.main.arn]
    }
    actions = ["sts:AssumeRoleWithWebIdentity"]
    condition {
      test     = "StringEquals"
      variable = "${replace(aws_eks_cluster.main.identity[0].oidc[0].issuer, "https://", "")}:sub"
      values = [
        for ns in var.external_secrets_namespaces : "system:serviceaccount:${ns}:external-secrets"
      ]
    }
  }
}

data "aws_eks_cluster_auth" "main" {
  name = aws_eks_cluster.main.name
}

data "aws_eks_cluster" "main" {
  name = aws_eks_cluster.main.name

  depends_on = [
    aws_eks_cluster.main,
    aws_eks_node_group.main
  ]
} 