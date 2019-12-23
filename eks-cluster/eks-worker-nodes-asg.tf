#
# EKS Worker Nodes Resources
#  * IAM role allowing Kubernetes actions to access other AWS services
#  * EC2 Security Group to allow networking traffic
#  * Data source to fetch latest EKS worker AMI
#  * AutoScaling Launch Configuration to configure worker instances
#  * AutoScaling Group to launch worker instances
#

resource "aws_iam_role" "asg-node" {
  name = "terraform-eks-asg-node"

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

resource "aws_iam_role_policy_attachment" "asg-node-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.asg-node.name
}

resource "aws_iam_role_policy_attachment" "asg-node-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.asg-node.name
}

resource "aws_iam_role_policy_attachment" "asg-node-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.asg-node.name
}

resource "aws_iam_role_policy_attachment" "asg-node-lb" {
  policy_arn = "arn:aws:iam::12345678901:policy/eks-lb-policy"
  role       = aws_iam_role.asg-node.name
}

resource "aws_iam_instance_profile" "asg-node" {
  name = "terraform-eks-asg"
  role = aws_iam_role.asg-node.name
}

resource "aws_security_group" "asg-node" {
  name        = "terraform-eks-asg-node"
  description = "Security group for all nodes in the cluster"

  vpc_id      = aws_vpc.eks.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${
    map(
     "Name", "terraform-eks-asg-node",
     "kubernetes.io/cluster/terraform-eks", "owned",
    )
  }"
}

resource "aws_security_group_rule" "asg-node-ingress-self" {
  description              = "Allow node to communicate with each other"
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.asg-node.id
  source_security_group_id = aws_security_group.asg-node.id
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "asg-node-ingress-cluster" {
  description              = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
  from_port                = 1025
  protocol                 = "tcp"
  security_group_id        = aws_security_group.asg-node.id
  source_security_group_id = aws_security_group.eks-cluster.id
  to_port                  = 65535
  type                     = "ingress"
}

data "aws_ami" "eks-worker" {
  filter {
    name   = "name"
    values = ["eks-worker-*"]
  }

  most_recent = true
  owners      = ["602401143452"] # Amazon
}

# EKS currently documents this required userdata for EKS worker nodes to
# properly configure Kubernetes applications on the EC2 instance.
# We utilize a Terraform local here to simplify Base64 encoding this
# information into the AutoScaling Launch Configuration.
# More information: https://amazon-eks.s3-us-west-2.amazonaws.com/1.10.3/2018-06-05/amazon-eks-nodegroup.yaml
locals {
  asg-node-userdata = <<USERDATA
#!/bin/bash -xe

CA_CERTIFICATE_DIRECTORY=/etc/kubernetes/pki
CA_CERTIFICATE_FILE_PATH=$CA_CERTIFICATE_DIRECTORY/ca.crt
mkdir -p $CA_CERTIFICATE_DIRECTORY
echo "${aws_eks_cluster.eks-cluster.certificate_authority.0.data}" | base64 -d >  $CA_CERTIFICATE_FILE_PATH
INTERNAL_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
sed -i s,MASTER_ENDPOINT,${aws_eks_cluster.eks-cluster.endpoint},g /var/lib/kubelet/kubeconfig
sed -i s,CLUSTER_NAME,${var.cluster-name},g /var/lib/kubelet/kubeconfig
sed -i s,REGION,${var.eks-region},g /etc/systemd/system/kubelet.service
sed -i s,MAX_PODS,20,g /etc/systemd/system/kubelet.service
sed -i s,MASTER_ENDPOINT,${aws_eks_cluster.eks-cluster.endpoint},g /etc/systemd/system/kubelet.service
sed -i s,INTERNAL_IP,$INTERNAL_IP,g /etc/systemd/system/kubelet.service
DNS_CLUSTER_IP=10.100.0.10
if [[ $INTERNAL_IP == 10.* ]] ; then DNS_CLUSTER_IP=172.20.0.10; fi
sed -i s,DNS_CLUSTER_IP,$DNS_CLUSTER_IP,g /etc/systemd/system/kubelet.service
sed -i s,CERTIFICATE_AUTHORITY_FILE,$CA_CERTIFICATE_FILE_PATH,g /var/lib/kubelet/kubeconfig
sed -i s,CLIENT_CA_FILE,$CA_CERTIFICATE_FILE_PATH,g  /etc/systemd/system/kubelet.service
systemctl daemon-reload
systemctl restart kubelet
USERDATA
}

resource "aws_launch_configuration" "eks-nodes" {
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.asg-node.name
  image_id                    = data.aws_ami.eks-worker.id
  instance_type               = "m4.large"
  name_prefix                 = "terraform-eks-asg"
  security_groups             = [aws_security_group.asg-node.id]
  user_data_base64            = "${base64encode(local.asg-node-userdata)}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "asg-nodes" {
  desired_capacity     = 2
  launch_configuration = aws_launch_configuration.eks-nodes.id
  max_size             = 2
  min_size             = 1
  name                 = "terraform-eks-asg"

  #  vpc_zone_identifier  = ["${aws_subnet.demo.*.id}"]
  vpc_zone_identifier = [aws_subnet.eks[*].id]

  tag {
    key                 = "Name"
    value               = "eks-asg-worker-node"
    propagate_at_launch = true
  }

  tag {
    key                 = "kubernetes.io/cluster/${var.cluster-name}"
    value               = "owned"
    propagate_at_launch = true
  }
}