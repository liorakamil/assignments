provider "aws" {
    region = var.aws_region
}

data "aws_caller_identity" "current" {}

# create an S3 bucket to store the state file in
resource "aws_s3_bucket" "state-s3" {
    bucket = "lio-hw-bucket"
 
    versioning {
      enabled = true
    }
 
    tags = {
      Name = "Terraform State Store"
    }      
}

data "aws_elb_service_account" "main" {}

resource "aws_s3_bucket" "access_logs" {
  bucket = "lio-hw-access-logs"
  acl    = "private"

  policy = <<POLICY
{
  "Id": "Policy",
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:PutObject"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::lio-hw-access-logs/AWSLogs/*",
      "Principal": {
        "AWS": [
          "${data.aws_elb_service_account.main.arn}"
        ]
      }
    }
  ]
}
POLICY
}

resource "aws_vpc" "mainvpc" {
    cidr_block = "${var.vpc_cidr}"
    enable_dns_hostnames = true
    tags = {
        Name = "HW-VPC"
    }
}

resource "aws_internet_gateway" "igw" {
    vpc_id = "${aws_vpc.mainvpc.id}"
    tags = {
        Name = "HW-IGW"
    }
}
resource "aws_eip" "eip-allocation" {
    vpc = true
}

resource "aws_nat_gateway" "ngw" {
  subnet_id     = "${aws_subnet.public1.id}"
  allocation_id = "${aws_eip.eip-allocation.id}"
  tags = {
    Name = "gw NAT"
  }
}

resource "aws_subnet" "public1" {
    vpc_id = "${aws_vpc.mainvpc.id}"
    cidr_block = "${var.public_subnet_cidr}"
    availability_zone = "us-east-1a"

    tags = {
        Name = "HW-Public Sub1"
    }
}

resource "aws_subnet" "public2" {
    vpc_id = "${aws_vpc.mainvpc.id}"
    cidr_block = "${var.public_subnet_cidr2}"
    availability_zone = "us-east-1b"

    tags = {
        Name = "HW-Public Sub2"
    }
}

resource "aws_route_table" "public-rt" {
    vpc_id = "${aws_vpc.mainvpc.id}"

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.igw.id}"
    }

    tags = {
        Name = "Public Route Table"
    }
}

resource "aws_route_table_association" "pub1" {
    subnet_id = "${aws_subnet.public1.id}"
    route_table_id = "${aws_route_table.public-rt.id}"
}
resource "aws_route_table_association" "pub2" {
    subnet_id = "${aws_subnet.public2.id}"
    route_table_id = "${aws_route_table.public-rt.id}"
}

resource "aws_subnet" "private1" {
    vpc_id = "${aws_vpc.mainvpc.id}"

    cidr_block = "${var.private_subnet_cidr}"
    availability_zone = "us-east-1a"

    tags = {
        Name = "HW-Private Sub1"
    }
}

resource "aws_subnet" "private2" {
    vpc_id = "${aws_vpc.mainvpc.id}"

    cidr_block = "${var.private_subnet_cidr2}"
    availability_zone = "us-east-1b"

    tags = {
        Name = "HW-Private Sub2"
    }
}

resource "aws_route_table" "private-rt" {
    vpc_id = "${aws_vpc.mainvpc.id}"

    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = "${aws_nat_gateway.ngw.id}"
    }

    tags = {
        Name = "Private Route Table"
    }
}

resource "aws_route_table_association" "priv1" {
    subnet_id = "${aws_subnet.private1.id}"
    route_table_id = "${aws_route_table.private-rt.id}"
}
resource "aws_route_table_association" "priv2" {
    subnet_id = "${aws_subnet.private2.id}"
    route_table_id = "${aws_route_table.private-rt.id}"
}

resource "aws_security_group" "HW-sg" {
 name        = "HW-sg"
 description = "security group for webservers"
 vpc_id      = "${aws_vpc.mainvpc.id}"
  egress {
   from_port   = 0
   to_port     = 0
   protocol    = "-1"
   cidr_blocks = ["0.0.0.0/0"]
 }

 egress {
   from_port   = 22
   to_port     = 22
   protocol    = "tcp"
   cidr_blocks = ["10.0.0.0/24"]
 }

  ingress {
   from_port   = 80
   to_port     = 80
   protocol    = "tcp"
   cidr_blocks = ["0.0.0.0/0"]
 }
}

resource "aws_security_group" "HW-database-sg" {
 name        = "HW-db-sg"
 description = "security group for databases"
 vpc_id      = "${aws_vpc.mainvpc.id}"
  egress {
   from_port   = 0
   to_port     = 0
   protocol    = "-1"
   cidr_blocks = ["10.0.0.0/24"]
 }

  ingress {
   from_port       = 22
   to_port         = 22
   protocol        = "tcp"
   security_groups = ["${aws_security_group.HW-sg.id}"]
 }
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

resource "aws_instance" "server1" {

  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"

  associate_public_ip_address = true
  subnet_id = "${aws_subnet.public1.id}"
  vpc_security_group_ids = [aws_security_group.HW-sg.id]
  key_name               = aws_key_pair.server_key.key_name
  user_data = <<-EOF
      #! /bin/bash
      sudo apt-get update
      sudo apt-get install -y apache2
      sudo systemctl start apache2
      sudo systemctl enable apache2
      HOSTNAME=$(cat /etc/hostname)
      echo "<h1>Welcome to Server1 $HOSTNAME</h1>" | sudo tee /var/www/html/index.html
    EOF
  tags = {
    Name = "Server1"
  }
}

resource "aws_instance" "server2" {

  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"

  associate_public_ip_address = true
  subnet_id = "${aws_subnet.public2.id}"
  vpc_security_group_ids = [aws_security_group.HW-sg.id]
  key_name               = aws_key_pair.server_key.key_name
  user_data = <<-EOF
        #! /bin/bash
        sudo apt-get update
        sudo apt-get install -y apache2
        sudo systemctl start apache2
        sudo systemctl enable apache2
        HOSTNAME=$(cat /etc/hostname)
        echo "<h1>Welcome to Server2 $HOSTNAME</h1>" | sudo tee /var/www/html/index.html
      EOF
  tags = {
    Name = "Server2"
  }
}

resource "aws_instance" "database2" {
  count = 1

  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"

  associate_public_ip_address = false
  subnet_id = "${aws_subnet.private2.id}"
  vpc_security_group_ids = [aws_security_group.HW-database-sg.id]
  key_name               = aws_key_pair.server_key.key_name

  tags = {
    Name = "database2"
  }
}

resource "aws_instance" "database1" {
  count = 1

  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"

  associate_public_ip_address = false
  subnet_id = "${aws_subnet.private1.id}"
  vpc_security_group_ids = [aws_security_group.HW-database-sg.id]
  key_name               = aws_key_pair.server_key.key_name

  tags = {
    Name = "database1"
  }
}

resource "aws_elb" "elb" {
  name               = "hw-elb"
  subnets = ["${aws_subnet.public1.id}", "${aws_subnet.public2.id}"]
  security_groups    = ["${aws_security_group.HW-ELB-sg.id}"]

  access_logs {
    bucket        = "${aws_s3_bucket.access_logs.id}"
    interval      = 60
    enabled       = true
  }
  
  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/"
    interval            = 30
  }

  instances                   = ["${aws_instance.server1.id}", "${aws_instance.server2.id}"]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags = {
    Name = "HW-terraform-elb"
  }
}

resource "aws_security_group" "HW-ELB-sg" {
 name        = "HW-ELB-sg"
 description = "security group for ELB"
 vpc_id      = "${aws_vpc.mainvpc.id}"
  egress {
   from_port   = 80
   to_port     = 80
   protocol    = "tcp"
   cidr_blocks = ["10.0.0.0/16"]
 }

  ingress {
   from_port   = 80
   to_port     = 80
   protocol    = "tcp"
   cidr_blocks = ["0.0.0.0/0"]
 }
}
terraform {
    backend "s3" {
    encrypt = true
    bucket = "lio-hw-bucket"
    region = "us-east-1"
    key = "hw-state.tfstate"
    }
}

#Stickiness:
resource "aws_lb_cookie_stickiness_policy" "stickiness" {
  name                     = "stickiness-policy"
  load_balancer            = "${aws_elb.elb.id}"
  lb_port                  = 80
  cookie_expiration_period = 60
}