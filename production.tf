resource "random_id" "random_id_prefix" {
  byte_length = 2
}
/*====
Variables used across all modules
======*/
locals {
  production_availability_zones = ["${var.region}a", "${var.region}b", "${var.region}c"]
}

data "aws_ssm_parameter" "ami" {
  name = "/aws/service/cloud9/amis/amazonlinux-2-x86_64"
}


data "aws_ami" "AmazonLinux2" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-kernel*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

module "networking" {
source = "./modules/networking"
  #region_name          = "${var.region}"
  environment          = "${var.environment}"
  vpc_cidr             = "${var.vpc_cidr}"
  public_subnets_cidr  = "${var.public_subnets_cidr}"
  private_subnets_cidr1 = "${var.private_subnets_cidr1}"
  private_subnets_cidr2 = "${var.private_subnets_cidr2}"
  private_subnets_cidr3 = "${var.private_subnets_cidr3}"
  #availability_zones   = "${local.production_availability_zones}"
}

#======================
## Cloud 9 Environment
#======================
resource "aws_cloud9_environment_ec2" "TestCloud9" {
  name = "Cloud9EC2Bastion-Terraform"
  instance_type = var.instance_type
  automatic_stop_time_minutes = 30
  connection_type = "CONNECT_SSH"
  #image_id = "amazonlinux-2-x86_64"
  image_id = "resolve:ssm:/aws/service/cloud9/amis/amazonlinux-2-x86_64"
  subnet_id = module.networking.public_subnets_id[0]
  description = "Cloud9 EC2 environment - Test"
  owner_arn = var.owner_arn
  tags      = {
    Terraform = "true"
    Project = "Demo"
  }
}

#=========================================
# Below resource is to create public key
#=========================================
resource "aws_key_pair" "Kafka_Client_key_pair" {
  key_name   = "${var.aws_public_key_name}"
  public_key = file("files/mykey.pub")
}

#===============================
# Security Group for Cloud9 Env
#===============================
data "aws_security_group" "cloud9_secgroup" {
    filter {
    name = "tag:aws:cloud9:environment"
        values = [
          aws_cloud9_environment_ec2.TestCloud9.id
        ]
    }
}
resource "aws_security_group_rule" "tcp_8080" {
    type              = "ingress"
    from_port         = 8080
    to_port           = 8080
    protocol          = "tcp"
    cidr_blocks       = ["0.0.0.0/0"]
    ipv6_cidr_blocks  = ["::/0"]
    security_group_id = data.aws_security_group.cloud9_secgroup.id
}


#============================
# Kafka Client  instance
#============================
data "aws_ami" "linux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["amazon"]
}

resource "aws_instance" "Kafka_Client" {
  ami                     = data.aws_ami.linux.id
  instance_type           = var.aws_instance_type
  #availability_zone       = "${var.aws_availability_zone}"
  key_name                = "${aws_key_pair.Kafka_Client_key_pair.id}"
  vpc_security_group_ids  = ["${aws_security_group.kafkaclient_sg.id}"]
  subnet_id               = module.networking.private_subnets_id-1[0]
  user_data               = fileexists("kafkabinariesInstall.sh") ? file("kafkabinariesInstall.sh") : null # # Install docker in the ubuntu
  tags = {
    Name = "Kafka_Client"
    Terraform = "true"
  }
}

#=================================
# Security Group for Kafka Client
#=================================
resource "aws_security_group" "kafkaclient_sg" {
  name        = "Security Groups for Kafka Client"
  description = "Allow SSH access to Kafka Client from Cloud9 and outbound internet access"
  vpc_id      = module.networking.vpc_id
  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "KafkaClient_sg_terraform"
  }
}

#----------------------------
# inbound for Kafka Client SG
#----------------------------
resource "aws_security_group_rule" "ssh" {
  protocol          = "TCP"
  from_port         = 22
  to_port           = 22
  type              = "ingress"
  #cidr_blocks       = var.allowed_hosts
  source_security_group_id = data.aws_security_group.cloud9_secgroup.id ## SSH only allowed from Cloud9
  security_group_id = aws_security_group.kafkaclient_sg.id
}

resource "aws_security_group_rule" "KafkaConnect" {
  protocol          = "TCP"
  from_port         = 8081
  to_port           = 8083
  type              = "ingress"
  source_security_group_id = aws_security_group.kafkaclient_sg.id
  security_group_id = aws_security_group.kafkaclient_sg.id
}

#-----------------------------
# Outbound for Kafka Client SG
#-----------------------------
resource "aws_security_group_rule" "internet" {
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.kafkaclient_sg.id
}



#==================================
# Security Group for Kafka Cluster
#==================================
resource "aws_security_group" "kafkaCluster_sg" {
  name        = "Security Groups for Kafka Cluster"
  description = "Allow SSH access to Kafka Client from Cloud9 and outbound internet access"
  vpc_id      = module.networking.vpc_id
  dynamic "ingress" {
    for_each = var.rules
    content {
      from_port = ingress.value["Fromport"]
      to_port   = ingress.value["Toport"] 
      protocol  = ingress.value["proto"]
      cidr_blocks = ingress.value["cidrs"]
    }
  }
  tags = {
    Name = "KafkaCluseter_sg_terraform"
  }
}

#------------------------------
# inbound for Kafka Cluster SG
#------------------------------
resource "aws_security_group_rule" "PlainTextClusterSG" {
  protocol          = "tcp"
  from_port         = 9094
  to_port           = 9094
  type              = "ingress"
  source_security_group_id = aws_security_group.kafkaclient_sg.id
  security_group_id = aws_security_group.kafkaCluster_sg.id
}

resource "aws_security_group_rule" "EncryptedClusterSG" {
  protocol          = "tcp"
  from_port         = 9092
  to_port           = 9092
  type              = "ingress"
  source_security_group_id = aws_security_group.kafkaclient_sg.id
  security_group_id = aws_security_group.kafkaCluster_sg.id
}

resource "aws_security_group_rule" "ZookeeperClusterSG" {
  protocol          = "tcp"
  from_port         = 2181
  to_port           = 2181
  type              = "ingress"
  source_security_group_id = aws_security_group.kafkaclient_sg.id
  security_group_id = aws_security_group.kafkaCluster_sg.id
}

resource "aws_security_group_rule" "fromPrometheusSG" {
  protocol          = "tcp"
  from_port         = 11001
  to_port           = 11002
  type              = "ingress"
  source_security_group_id = aws_security_group.Prometheus_sg.id
  security_group_id = aws_security_group.kafkaCluster_sg.id
}

#------------------------------
#Outbound for Kafka Cluster SG
#------------------------------
resource "aws_security_group_rule" "internetClusterSG" {
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.kafkaCluster_sg.id
}

#======================================
# Security Group for Prometheus Server
#======================================
resource "aws_security_group" "Prometheus_sg" {
  name        = "Security Groups for Prometheus Server"
  description = "Allow SSH access to Kafka Client from Cloud9 and outbound internet access"
  vpc_id      = module.networking.vpc_id
  dynamic "ingress" {
    for_each = var.rules
    content {
      from_port = ingress.value["Fromport"]
      to_port   = ingress.value["Toport"] 
      protocol  = ingress.value["proto"]
      cidr_blocks = ingress.value["cidrs"]
    }
  }
  tags = {
    Name = "Prometheus_sg_terraform"
  }
}

#---------------------------------
#Outbound for Prometheus Server SG
#---------------------------------
resource "aws_security_group_rule" "internetPrometheusSG" {
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.Prometheus_sg.id
}
