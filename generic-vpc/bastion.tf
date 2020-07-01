resource "aws_key_pair" "bastion" {
    key_name   = "bastion-key"
    public_key = file("id_rsa.pub")
}

resource "aws_eip" "bastion_ip" {
    instance = aws_instance.bastion.id
    vpc      = true

    tags = {
        Name = "bastion EIP"
    }
}

resource "aws_eip_association" "eip_assoc" {
    instance_id   = aws_instance.bastion.id
    allocation_id = aws_eip.bastion_ip.id
}

resource "aws_instance" "bastion" {
    ami                       = data.aws_ami.ubuntu.id
    instance_type             = "t2.micro"
    key_name                  = "bastion-key"
    subnet_id                 = aws_subnet.terraform_public[0].id
    vpc_security_group_ids    = [aws_security_group.bastion.id]

    # Userdata to always pull *.pub from bucket to autherize_keys
    # create cron to run every * minutes

    tags = {
        Name = "bastion"
    }
}
