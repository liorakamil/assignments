terraform {
  required_version = ">= 0.12.0"
}

variable "aws_region" {
  description = "AWS region"
  default     = "us-east-1"
}

variable "vpc_cidr" {
  default     = "10.0.0.0/16"
}
variable "vpc_private_subnets" {
    type    = list(string)
    default = ["10.0.1.0/24", "10.0.2.0/24"]
}
variable "vpc_public_subnets" {
    type    = list(string)
    default = ["10.0.101.0/24", "10.0.102.0/24"]
}

variable "aws_azs" {
    type    = list(string)
    default = ["us-east-1a", "us-east-1a"]
}

variable "ingress_ports" {
  type        = list(number)
  description = "list of ingress ports"
  default     = [22]
}
variable "cluster_tag_key" {
  description = "The tag the EC2 Instances will look for to automatically discover each other and form a cluster."
  type        = string
  default     = "consul-servers"
}

variable "cluster_name" {
  description = "What to name the Consul cluster and all of its associated resources"
  type        = string
  default     = "consul-server"
}