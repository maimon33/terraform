provider "aws" {
    region = var.region
    version = ">= 2.68"
}

provider "http" {
    version = ">= 1.2"
}

data "aws_availability_zones" "available" {}

data "http" "myip" {
    url = "http://ipv4.icanhazip.com"
}