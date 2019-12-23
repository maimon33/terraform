#
# EKS Worker Nodes Resources
#  * IAM role allowing Kubernetes actions to access other AWS services
#  * EKS Node Group to launch worker nodes
#

resource "aws_iam_role" "eks-node" {
  name = "terraform-eks-node"

  assume_role_policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor8",
            "Effect": "Allow",
            "Principal": {
                "Service": "ec2.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        },
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "s3:PutAccountPublicAccessBlock",
                "s3:GetAccountPublicAccessBlock",
                "s3:ListAllMyBuckets",
                "route53:ListHostedZones",
                "s3:HeadBucket"
            ],
            "Resource": "*"
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": [
                "s3:ListBucketByTags",
                "s3:GetLifecycleConfiguration",
                "s3:GetBucketTagging",
                "s3:GetInventoryConfiguration",
                "s3:GetObjectVersionTagging",
                "s3:ListBucketVersions",
                "s3:GetBucketLogging",
                "s3:ListBucket",
                "s3:ListObjects",
                "s3:GetAccelerateConfiguration",
                "s3:GetBucketPolicy",
                "s3:GetObjectVersionTorrent",
                "s3:GetObjectAcl",
                "s3:GetBucketRequestPayment",
                "s3:GetObjectVersionAcl",
                "route53:ListResourceRecordSets",
                "s3:GetObjectTagging",
                "s3:GetMetricsConfiguration",
                "s3:ListBucketMultipartUploads",
                "s3:GetBucketWebsite",
                "route53:ChangeResourceRecordSets",
                "s3:GetBucketVersioning",
                "s3:GetBucketAcl",
                "s3:GetBucketNotification",
                "s3:GetReplicationConfiguration",
                "s3:ListMultipartUploadParts",
                "s3:GetObject",
                "s3:GetObjectTorrent",
                "s3:GetIpConfiguration",
                "s3:GetBucketCORS",
                "s3:GetAnalyticsConfiguration",
                "s3:GetObjectVersionForReplication",
                "s3:GetBucketLocation",
                "s3:GetObjectVersion"
            ],
            "Resource": [
                "arn:aws:s3:::fdna-academy-${var.environment}-config/*",
                "arn:aws:s3:::fdna-academy-${var.environment}-config",
                "arn:aws:s3:::fdna-user-blobs-${var.environment}-new/*",
                "arn:aws:s3:::fdna-user-blobs-${var.environment}-new",
                "arn:aws:s3:::fdna-${var.environment}-new-config/*",
                "arn:aws:s3:::fdna-${var.environment}-new-config",
                "arn:aws:s3:::fdna-${var.environment}-config/*",
                "arn:aws:s3:::fdna-${var.environment}-config",
                "arn:aws:route53:::hostedzone/Z1OYCQZ9S3ZJJ2"
            ]
        },
        {
            "Sid": "VisualEditor2",
            "Effect": "Allow",
            "Action": [
                "route53:GetChange",
                "s3:*"
            ],
            "Resource": [
                "arn:aws:route53:::hostedzone/Z1OYCQZ9S3ZJJ2",
                "arn:aws:s3:::fdna-user-blobs-${var.environment}",
                "arn:aws:s3:::/*"
            ]
        },
        {
            "Sid": "VisualEditor3",
            "Effect": "Allow",
            "Action": "s3:*",
            "Resource": [
                "arn:aws:s3:::fdna-user-blobs-${var.environment}-new/*",
                "arn:aws:s3:::fdna-user-blobs-${var.environment}/*",
                "arn:aws:s3:::fdna-${var.environment}-config/*",
                "arn:aws:s3:::fdna-user-blobs-${var.environment}-new",
                "arn:aws:s3:::fdna-user-blobs-${var.environment}",
                "arn:aws:s3:::fdna-${var.environment}-config"
            ]
        },
        {
            "Sid": "VisualEditor4",
            "Effect": "Allow",
            "Action": "s3:*",
            "Resource": [
                "arn:aws:s3:::fdna-solutions-${var.environment}-config/*",
                "arn:aws:s3:::fdna-solutions-${var.environment}-config"
            ]
        }
    ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "eks-node-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks-node.name
}

resource "aws_iam_role_policy_attachment" "eks-node-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks-node.name
}

resource "aws_iam_role_policy_attachment" "eks-node-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks-node.name
}

resource "aws_eks_node_group" "eks-cluster" {
  cluster_name    = aws_eks_cluster.eks-cluster.name
  node_group_name = "eks"
  node_role_arn   = aws_iam_role.eks-node.arn
  subnet_ids      = aws_subnet.eks[*].id

  scaling_config {
    desired_size = 1
    max_size     = 1
    min_size     = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks-node-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.eks-node-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.eks-node-AmazonEC2ContainerRegistryReadOnly,
  ]
}
