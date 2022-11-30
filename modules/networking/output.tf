output "vpc_id" {
  value = "${aws_vpc.vpc.id}"
}

output "public_subnets_id" {
  value = ["${aws_subnet.public_subnet[0].id}"]
}

output "private_subnets_id-1" {
  value = ["${aws_subnet.private_subnet1[0].id}"]
}

output "private_subnets_id-2" {
  value = ["${aws_subnet.private_subnet2[0].id}"]
}

output "private_subnets_id-3" {
  value = ["${aws_subnet.private_subnet3[0].id}"]
}

output "default_sg_id" {
  value = ["${aws_security_group.default.id}"]
}

output "security_groups_ids" {
  value = ["${aws_security_group.default.id}"]
}

output "public_route_table" {
  value = ["${aws_route_table.public.id}"]
}