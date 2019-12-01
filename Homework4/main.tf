provider "aws" {
    region = var.aws_region
}

data "aws_subnet_ids" "subnets" {
    vpc_id = var.vpc_id
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "tls_private_key" "server_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "server_key" {
  key_name   = "server_key"
  public_key = "${tls_private_key.server_key.public_key_openssh}"
}

resource "aws_security_group" "ansible-sg" {
 name        = "ansible-sg"
 description = "security group for ansible servers"
 vpc_id      = var.vpc_id
  egress {
   from_port   = 0
   to_port     = 0
   protocol    = "-1"
   cidr_blocks = ["0.0.0.0/0"]
 }

  dynamic "ingress" {
    iterator = port
    for_each = var.ingress_ports
    content {
      from_port   = port.value
      to_port     = port.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  ingress {
   from_port   = 8
   to_port     = 0
   protocol    = "icmp"
   cidr_blocks = ["0.0.0.0/0"]
 }
}

resource "aws_instance" "server" {
  count = 1

  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"

  associate_public_ip_address = true

  vpc_security_group_ids = [aws_security_group.ansible-sg.id]
  key_name               = aws_key_pair.ansible_key.key_name

  user_data = <<-EOF
  #! /bin/bash
  sudo apt update -y
  sudo apt install -y software-properties-common
  sudo apt-add-repository --yes --update ppa:ansible/ansible
  sudo apt install -y ansible
  sudo apt-get install -y makepasswd
  sudo apt install whois
  EOF

  tags = {
    Name = "Server"
  }
}

resource "aws_instance" "nodes" {
  count =2 

  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"

  associate_public_ip_address = true

  vpc_security_group_ids = [aws_security_group.ansible-sg.id]
  key_name               = aws_key_pair.ansible_key.key_name

  tags = {
    Name = "Node${count.index}"
  }
}

