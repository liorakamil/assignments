provider "aws" {
    region = var.aws_region
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

  ingress {
   from_port   = 80
   to_port     = 80
   protocol    = "tcp"
   cidr_blocks = ["0.0.0.0/0"]
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

resource "aws_instance" "server" {
  count = 1

  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"

  associate_public_ip_address = true
  subnet_id = "${aws_subnet.public1.id}"
  vpc_security_group_ids = [aws_security_group.HW-sg.id]
  key_name               = aws_key_pair.server_key.key_name

  tags = {
    Name = "Server1"
  }
}

resource "aws_db_subnet_group" "db-group" {
  name       = "hw-db-subnets"
  subnet_id = ["${aws_subnet.private2.id}", "${aws_subnet.private1.id}"]
  tags = {
    Name = "My DB subnet group"
  }
}

resource "aws_db_instance" "db-server" {
  allocated_storage = 10
  storage_type = "gp2"
  engine = "mysql"
  engine_version = "5.7.22"
  instance_class  = "db.t2.micro"
  skip_final_snapshot = "true"
  name = "database1"
  username = "adminuser"
  password = "adminpass"
  db_subnet_group_name = "hw-db-subnets"
}

