terraform {
  required_version = ">= 0.12.0"
}

variable "aws_region" {
    description = "AWS region"
    default = "us-east-1"
}

variable "availability_zone_names" {
  type    = list(string)
  default = ["us-east-1"]
}

variable "vpc_cidr" {
    description = "CIDR for the whole VPC"
    default = "10.0.0.0/16"
}

variable "public_subnet_cidr1" {
    description = "CIDR for the Public Subnet"
    default = "10.0.1.0/24"
}

variable "public_subnet_cidr2" {
    description = "CIDR for the Public Subnet"
    default = "10.0.10.0/24"
}

variable "private_subnet_cidr1" {
    description = "CIDR for the Private Subnet"
    default = "10.0.2.0/24"
}

variable "private_subnet_cidr2" {
    description = "CIDR for the Private Subnet"
    default = "10.0.20.0/24"
}

variable "ingress_ports" {
  type        = list(number)
  description = "list of ingress ports"
  default     = [22]
}

