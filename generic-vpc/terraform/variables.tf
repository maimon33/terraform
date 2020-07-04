variable "region" {
    default = "eu-west-1"
    type    = string
}

variable "vpc_cidr" {
    default = "172.16.0.0/16"
    type    = string
}

variable "env_name" {
    default = "terraform"
    type    = string
}

variable "backend_bucket" {
    default = ""
    type    = string
}