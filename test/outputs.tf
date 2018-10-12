output "aws_vpc_id" {
  value = "${aws_vpc.default.id}"
}

output "ip" {
  value = "${aws_eip.ip.public_ip}"
}

output "subnet_id" {
  value = "${aws_subnet.default.id}"
}

