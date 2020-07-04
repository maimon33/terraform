resource "aws_key_pair" "bastion" {
    key_name   = "bastion-key"
    public_key = file("id_rsa.pub")
}

resource "aws_eip" "bastion_eip" {
    instance = aws_instance.bastion.id
    vpc      = true
}

resource "aws_eip_association" "eip_assoc" {
    instance_id   = aws_instance.bastion.id
    allocation_id = aws_eip.bastion_eip.id
}

resource "aws_instance" "bastion" {
    ami                         = data.aws_ami.ubuntu.id
    instance_type               = "t2.micro"
    key_name                    = "bastion-key"
    associate_public_ip_address = true
    subnet_id                   = aws_subnet.terraform_public[0].id
    vpc_security_group_ids      = [aws_security_group.bastion.id]
    iam_instance_profile        = aws_iam_instance_profile.bastion_profile.name

    # Userdata to always pull *.pub from bucket to autherize_keys
    # create cron to run every * minutes
    provisioner "file" {
    source      = "bastion-source"
    destination = "/home/ubuntu/bastion"
  }
    
    provisioner "remote-exec" {
        inline = [
        "sudo apt update",
        "sudo apt-get install awscli -y",
        "chmod +x /home/ubuntu/bastion/bastion-keys.sh",
        "sed -i 's/SED_BUCKET/${var.backend_bucket}/g' /home/ubuntu/bastion/bastion-keys.sh",
        "cat /home/ubuntu/bastion/bastion-cron | crontab -",
        ]
    }

    connection {
        type        = "ssh"
        user        = "ubuntu"
        password    = ""
        private_key = file("./id_rsa")
        host        = self.public_ip
    }

    tags = {
        Name = "bastion"
    }
}
