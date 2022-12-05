################################################################################
# Configuration
################################################################################

output "VPC_ID" {
  description = "VPC ID of the newly created Amazon VPC"
  value       = try(module.networking.vpc_id, "")
}

output "public_subnet_id" {
  description = "Public Subnet ID for newly created VPC"
  #value       = [try(module.networking.public_subnets_id, "")]
  value       = try(module.networking.public_subnets_id, "")[0]
}

output "private_subnet_id1" {
  description = "Private Subnet ID-1 for newly created VPC"
  #value       = [try(module.networking.private_subnets_id-1, "")]
  value       = try(module.networking.private_subnets_id-1, "")[0]
}

output "private_subnet_id2" {
  description = "Private Subnet ID-2 for newly created VPC"
  #value       = [try(module.networking.private_subnets_id-2, "")]
  value       = try(module.networking.private_subnets_id-2, "")[0]
}

output "private_subnet_id3" {
  description = "Private Subnet ID-3 for newly created VPC"
  #value       = [try(module.networking.private_subnets_id-3, "")]
  value       = try(module.networking.private_subnets_id-3, "")[0]
}

output "default_SecGrp_ID" {
  description = "Default Security Group ID for newly created VPC"
  #value       = [try(module.networking.default_sg_id, "")]
  value       = try(module.networking.default_sg_id, "")[0]
}

output "public_route_table_ID" {
  description = "Pubblic Route Table ID for newly created VPC"
  #value       = [try(module.networking.public_route_table, "")]
  value       = try(module.networking.public_route_table, "")[0]
}

###############################
### Cloud9 Environment Outputs
###############################
output "cloud9_url" {
  value = "https://${var.region}.console.aws.amazon.com/cloud9/ide/${aws_cloud9_environment_ec2.TestCloud9.id}"
}

output "Cloud9_id" {
  value = aws_cloud9_environment_ec2.TestCloud9.id
}

output "Cloud9_arn" {
  value = aws_cloud9_environment_ec2.TestCloud9.arn
}

output "Cloud9_Instance_type" {
  value = aws_cloud9_environment_ec2.TestCloud9.type
}


###############################
### Security Group Outputs
###############################
output "Prometheus_SecGrp_ID" {
  description = "Security Group ID for Prometheus Server"
  value       = try(aws_security_group.Prometheus_sg.id, "")
}

output "KafkaCluster_SecGrp_ID" {
  description = "Security Group ID for Kafka Cluster"
  value       = try(aws_security_group.kafkaCluster_sg.id, "")
}

output "KafkaClient_SecGrp_ID" {
  description = "Security Group ID for Kafka Client"
  value       = try(aws_security_group.kafkaclient_sg.id, "")


############
### Key Pair
############
output "private_key" {
  value     = tls_private_key.DemoPrivateKey.private_key_pem
  sensitive = true
}}
