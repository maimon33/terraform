resource "aws_vpc" "tf-vpc" {
  cidr_block = var.vpc-cidr

  tags = {
    Name = "terraform-vpc"
  }
}

resource "aws_subnet" "tf-public" {
  count = 3

  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = cidrsubnet(var.vpc-cidr, 8, count.index)
  vpc_id            = aws_vpc.tf-vpc.id

  tags = {
    Name = "terraform-public_subnet"
  }
}

resource "aws_subnet" "tf-private" {
  count = 3

  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = cidrsubnet(var.vpc-cidr, 8, count.index + 3)
  vpc_id            = aws_vpc.tf-vpc.id

  tags = {
    Name = "terraform-private_subnet"
  }
}

resource "aws_internet_gateway" "terraform_igw" {
  vpc_id = aws_vpc.tf-vpc.id

  tags = {
    Name = "terraform igw"
  }
}

resource "aws_route_table" "tf-public-rt" {
  vpc_id = aws_vpc.tf-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.terraform_igw.id
  }
}

resource "aws_route_table" "tf-private-rt" {
  vpc_id = aws_vpc.tf-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.terraform_nat_gw.id
  }
}

resource "aws_route_table_association" "tf-public-rt-assoc" {
  count = 3

  subnet_id      = aws_subnet.tf-public.*.id[count.index]
  route_table_id = aws_route_table.tf-public-rt.id
}

resource "aws_route_table_association" "tf-private-rt-assoc" {
  count = 3

  subnet_id      = aws_subnet.tf-private.*.id[count.index]
  route_table_id = aws_route_table.tf-private-rt.id
}

resource "aws_eip" "terraform_eip" {
  vpc      = true
}

resource "aws_nat_gateway" "terraform_nat_gw" {
  allocation_id = aws_eip.terraform_eip.id
  subnet_id     = aws_subnet.tf-private["0"].id

  tags = {
    Name = "terraform NAT gw"
  }
}