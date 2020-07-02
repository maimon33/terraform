resource "aws_iam_role" "bastion_role" {
  name = "bastion_role"

  assume_role_policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "ec2.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
  }
  EOF
}

resource "aws_iam_instance_profile" "bastion_profile" {
  name = "bastion_profile"
  role = aws_iam_role.bastion_role.name
}

resource "aws_iam_role_policy" "bastion_policy" {
  name = "bastion_policy"
  role = aws_iam_role.bastion_role.id

  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": [
          "s3:*"
        ],
        "Effect": "Allow",
        "Resource": "*"
      }
    ]
  }
  EOF
}

resource "aws_security_group" "allow_internet" {
  name        = "allow_internet"
  description = "Allow outbound internet access"
  vpc_id      = aws_vpc.terraform-vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Internet"
  }
}

resource "aws_security_group" "bastion" {
  name        = "bastion_group"
  description = "Inbound SSH to bastion"
  vpc_id      = aws_vpc.terraform-vpc.id

  ingress {
    description = "Allow SSH from users IP"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["${chomp(data.http.myip.body)}/32"]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "bastion group"
  }
}

resource "aws_security_group" "backend_servers" {
  name        = "backend_servers_group"
  description = "Allow inbound from bastion and app servers"
  vpc_id      = aws_vpc.terraform-vpc.id

  ingress {
    description = "Allow ALL from bastion and application servers"
    from_port = 0
    to_port = 0
    protocol = "-1"
    security_groups = [ aws_security_group.bastion.id , aws_security_group.app_servers.id ]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "backend group"
  }
}

resource "aws_security_group" "app_servers" {
  name        = "app_servers_group"
  description = "Allow inbound from bastion"
  vpc_id      = aws_vpc.terraform-vpc.id

  ingress {
    description = "Allow ALL from bastion"
    from_port = 0
    to_port = 0
    protocol = "-1"
    security_groups = [ aws_security_group.bastion.id ]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "app group"
  }
}