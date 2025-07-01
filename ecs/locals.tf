data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  vpc_cidr_block = var.vpc_cidr

  vpc_mask = tonumber(split("/", local.vpc_cidr_block)[1])
  max_subnet_mask = var.subnet_mask
  subnet_bits = min(local.max_subnet_mask - local.vpc_mask, 8)
  total_subnets = pow(2, local.subnet_bits)

  subnet_blocks = [
    for i in range(local.total_subnets) :
    cidrsubnet(local.vpc_cidr_block, local.subnet_bits, i)
  ]

  # Use sorted AZs to ensure deterministic but spread placement
  sorted_azs = sort(data.aws_availability_zones.available.names)

  public_subnets = [
    for i in range(3) : {
      cidr_block        = local.subnet_blocks[i]
      availability_zone = local.sorted_azs[i % length(local.sorted_azs)]
    }
  ]

  private_subnets = [
    for i in range(3, local.total_subnets) : {
      cidr_block        = local.subnet_blocks[i]
      availability_zone = local.sorted_azs[i % length(local.sorted_azs)]
    }
  ]
}