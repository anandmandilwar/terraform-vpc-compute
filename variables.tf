variable "region" {
  description = "AWS Deployment region.."
  default = "us-east-1"
}

variable "environment" {
  description = "The Deployment environment"
  default = "Demo"
}

//Networking
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

variable "project" {
  description = "name of the project"
  type = string
  default = "TestCloud9-Project-terraform"
}

####
variable "name" {
  description = "Environment name"
}

variable "instance_type" {
  description = "AWS instance type to assign"
  default = "t3.medium"
}

variable "automatic_stop_time_minutes" {
  description = "Minutes of inactivity before the instance is shut down"
  default     = 30
}


variable "owner_arn" {
  description = "ARN of the environment owner"
}

variable "tags" {
  description = "Mapping of tags to assign to resources"
  type        = map
  default     = {
    "Project" = ""
    "Terraform" = "true"
  }
}

variable "aws_instance_type" {
  type    = string
  default = "t3.medium"
}

variable "aws_public_key_name" {
  default = "prometheus_aws_rsa"
}

variable "rules" {
  default = [
    {
      Fromport    = 80
      Toport      = 80
      proto       = "tcp"
      cidrs = ["10.0.0.0/24"]  
    },
    {
      Fromport      = 3500
      Toport      = 3900
      proto     = "tcp"
      cidrs = ["10.0.0.0/24"]
    }
  ]
}

variable "Promentheus_Ingress_rules" {
  default = [
    {
      Fromport    = 22
      Toport      = 22
      proto       = "tcp"
      cidrs = ["10.0.0.0/24"]  
    },
    {
      Fromport      = 9090
      Toport      = 9090
      proto     = "tcp"
      cidrs = ["0.0.0.0/0"]
    }
  ]
}
