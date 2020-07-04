output "bastion_ip" {
    value = aws_eip.bastion_eip.public_ip
}

output "private_subnets" {
    value = aws_subnet.terraform_private.*.id
}

output "public_subnets" {
    value = aws_subnet.terraform_public.*.id
}

output "vpc_id" {
    value = aws_vpc.terraform-vpc.id
}