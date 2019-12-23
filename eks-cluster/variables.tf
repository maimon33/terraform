#
# Variables Configuration
#

variable "environment" {
  default = ""
  type    = string
}

variable "eks-region" {
  default = "eu-=west-1"
  type    = string
}

variable "terraform-bucket" {
  default = ""
  type    = string
}

variable "cluster-name" {
  default = "terraform-eks"
  type    = string
}


variable "keypair" {
  default = ""
  type    = string
}
