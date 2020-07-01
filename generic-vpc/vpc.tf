resource "aws_vpc" "terraform-vpc" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "${var.env_name}-vpc"
  }
}

resource "aws_subnet" "terraform_public" {
  count = length(data.aws_availability_zones.available.names)

  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index)
  vpc_id            = aws_vpc.terraform-vpc.id

  tags = {
    Name = "${var.env_name}-public_subnet"
  }
}

resource "aws_subnet" "terraform_private" {
  count = length(data.aws_availability_zones.available.names)

  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 3)
  vpc_id            = aws_vpc.terraform-vpc.id

  tags = {
    Name = "${var.env_name}-private_subnet"
  }
}

resource "aws_internet_gateway" "terraform_igw" {
  vpc_id = aws_vpc.terraform-vpc.id

  tags = {
    Name = "${var.env_name} igw"
  }
}

resource "aws_route_table" "terraform_public_route_table" {
  vpc_id = aws_vpc.terraform-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.terraform_igw.id
  }
}

resource "aws_route_table" "terraform_private_route_table" {
  vpc_id = aws_vpc.terraform-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.terraform_nat_gw.id
  }
}

resource "aws_route_table_association" "terraform_public_route_table_assoc" {
  count = 3

  subnet_id      = aws_subnet.terraform_public.*.id[count.index]
  route_table_id = aws_route_table.terraform_public_route_table.id
}

resource "aws_route_table_association" "terraform_private_route_table_assoc" {
  count = 3

  subnet_id      = aws_subnet.terraform_private.*.id[count.index]
  route_table_id = aws_route_table.terraform_private_route_table.id
}

resource "aws_eip" "terraform_eip" {
  vpc      = true
}

resource "aws_nat_gateway" "terraform_nat_gw" {
  allocation_id = aws_eip.terraform_eip.id
  subnet_id     = aws_subnet.terraform_private["0"].id

  tags = {
    Name = "${var.env_name} NAT gw"
  }
}