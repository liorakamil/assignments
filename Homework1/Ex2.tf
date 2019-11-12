provider "aws" {
    profile = "default"
    region = "us-east-1"
}

resource "aws_security_group" "instance_sg" {
  name = "sgex2"
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_instance" Exersice2 {
    count = 2
    ami = "ami-024582e76075564db"
    instance_type = "t2.micro"
    key_name = "ex-key"
    vpc_security_group_ids = [aws_security_group.instance_sg.id]
    tags = {
        Name = "nginx ${count.index}"
        Owner = "liorakamil"
        Purpose = "learning"
    }
    root_block_device {
    }
    ebs_block_device {
        device_name = "/dev/sdf"
        volume_type = "gp2"
        volume_size = 10
        encrypted = true
    }
    
    user_data = <<-EOF
    #! /bin/bash
    sudo apt update
    sudo apt install -y nginx
    echo "OpsSchool Rules" > /var/www/html/index.nginx-debian.html
    sudo systemctl enable nginx
    sudo systemctl start nginx
    EOF
}







