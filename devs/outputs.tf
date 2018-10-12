output "aws_vpc_id" {
  value = "${aws_vpc.develop.id}"
}

output "subnet_id" {
  value = "${aws_subnet.develop.id}"
}

