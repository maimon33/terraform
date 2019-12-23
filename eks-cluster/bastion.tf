# Bastion server for EKS cluster

resource "aws_eip" "bastion_ip" {
  instance = aws_instance.bastion.id
  vpc      = true
}

resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.bastion.id
  allocation_id = aws_eip.bastion_ip.id
}

resource "aws_security_group" "eks-cluster-bastion-access" {
  name        = "allow_to_bastion"
  description = "Allow access to bastion"
  vpc_id      = aws_vpc.eks.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks       = ["${local.workstation-external-cidr}"]
  }

  tags = {
    Name = "allow FDNA"
  }
}

resource "aws_instance" "bastion" {
  ami           = "ami-08a61b12225c1465c"
  instance_type = "t2.micro"
  key_name      = var.keypair
  subnet_id     = aws_subnet.eks[0].id
  vpc_security_group_ids   = [aws_security_group.eks-cluster-bastion-access.id]

  tags = map(
    "Name", "${chomp(var.cluster-name)}-bastion",
    "environment", "${var.environment}",
    )
}
