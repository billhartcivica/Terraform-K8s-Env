# Specify the provider and access details
provider "aws" {
  region = "eu-west-2"
}

# Create a VPC to launch our instances into
resource "aws_vpc" "default" {
  cidr_block = "10.22.0.0/16"

  tags {
    Name = "EGAR-TEST-VPC"
    project = "EGAR"
    egar = "vpc"
  }
}

# Create an internet gateway to give our subnet access to the outside world
resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.default.id}"

  tags {
    Name = "EGAR-TEST-GW"
    project = "EGAR"
    egar = "gw"
  }
}

# Grant the VPC internet access on its main route table
resource "aws_route" "internet_access" {
  route_table_id         = "${aws_vpc.default.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.default.id}"
}

# Create a subnet to launch our instances into
resource "aws_subnet" "default" {
  vpc_id                  = "${aws_vpc.default.id}"
  cidr_block              = "10.22.10.0/24"
  map_public_ip_on_launch = true

  tags {
    Name = "EGAR-TEST-Subnet"
    project = "EGAR"
    egar = "subnet"
  }
}

# Our default security group to access
# the instances over SSH and HTTP
resource "aws_security_group" "default" {
  name        = "terraform_example"
  description = "EGAR Test Security Group"
  vpc_id      = "${aws_vpc.default.id}"

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH from Anywhere"
  }

  # HTTP access from the VPC
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP from Anywhere"
  }

  # HTTPS access from anywhere
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS from Anywhere"
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow All Outbound"
  }

  tags {
    Name = "EGAR-TEST-SecurityGrp"
    project = "EGAR"
    egar = "secgrp"
  }
}

resource "aws_instance" "web" {
  # The connection block tells our provisioner how to
  # communicate with the resource (instance)
  connection {
    # The default username for our AMI
    type = "ssh"
    user = "ec2-user"
    private_key = "${file("EGAR.pem")}"
    # The connection will use the local SSH agent for authentication.
  }

  instance_type = "t2.micro"

  # Lookup the correct AMI based on the region
  # we specified
  ami = "ami-b2b55cd5"

  # The name of our SSH keypair we created above.
  key_name = "EGAR"

  # Our Security group to allow HTTP, HTTPS and SSH access
  vpc_security_group_ids = ["${aws_security_group.default.id}"]

  # We're going to launch into the same subnet as our ELB. In a production
  # environment it's more common to have a separate private subnet for
  # backend instances.
  subnet_id = "${aws_subnet.default.id}"

  # Add tags to host
  tags {
    Name = "EGAR-TEST-PROXY"
    project = "egar"
    egar = "ec2"
    Owner = "egar-admin"
  }

  # We run a remote provisioner on the instance after creating it.
  # In this case, we just install nginx and start it. By default,
  # this should be on port 80
  provisioner "remote-exec" {
    inline = [
      "sudo yum -y update",
      "sudo yum -y install nginx",
      "sudo service nginx start",
    ]
  }
}

resource "aws_eip" "ip" {
  instance = "${aws_instance.web.id}"
}

