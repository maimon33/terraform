variable "region" {
  default = "us-east-1"
}

variable "ecs_cluster_name" {
  default = "ecs-cluster"
}

variable "vpc_cidr" {
  default = "10.0.0.0/20"
}

# Subnet mask must be at least 2 bits higher than the VPC mask (i.e., subnets must be smaller).
# Example usable IPs in AWS:
#   /24 = 251 usable IPs (256 - 5 reserved)
#   /23 = 507 usable IPs (512 - 5 reserved)
#   /22 = 1019 usable IPs (1024 - 5 reserved)
variable "subnets_mask" {
  default = "24"
}

variable "asg_subnet_ids" {
  type        = list(string)
  description = "Optional list of private subnet IDs for the Auto Scaling Group"
  default     = []
}
