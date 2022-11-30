variable "environment" {
  description = "AWS Deployment Environment"
  default = "Demo"
}


variable "vpc_cidr" {
  description = "AWS VPC CIDR"
  default = "10.0.0.0/16"
}

variable "public_subnets_cidr" {
  description = "AWS VPC Public Subnet CIDR"
  type = list
  default = ["10.0.0.0/24"]
}

variable "private_subnets_cidr1" {
  description = "AWS VPC Private Subnet-1 CIDR"
  type = list
  default = ["10.0.1.0/24"]
}

variable "private_subnets_cidr2" {
  description = "AWS VPC Private Subnet-2 CIDR"
  type = list
  default = ["10.0.2.0/24"]
}

variable "private_subnets_cidr3" {
  description = "AWS VPC Private Subnet-3 CIDR"
  type = list
  default = ["10.0.3.0/24"]
}
