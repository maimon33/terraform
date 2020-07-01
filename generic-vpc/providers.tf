provider "aws" {
  region = "eu-west-1"
}

data "aws_availability_zones" "available" {}