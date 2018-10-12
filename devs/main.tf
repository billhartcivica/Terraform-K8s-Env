# Specify the provider and access details
provider "aws" {
  region = "eu-west-2"
}

# Create a VPC to launch our instances into
resource "aws_vpc" "develop" {
  cidr_block = "10.20.0.0/16"

  tags {
    Name = "EGAR-DEVELOPER-VPC"
    project = "EGAR"
    egar = "vpc"
  }
}

# Create an internet gateway to give our subnet access to the outside world
resource "aws_internet_gateway" "develop" {
  vpc_id = "${aws_vpc.develop.id}"

  tags {
    Name = "EGAR-DEVELOPER-GW"
    project = "EGAR"
    egar = "gw"
  }
}

# Grant the VPC internet access on its main route table
resource "aws_route" "internet_access" {
  route_table_id         = "${aws_vpc.develop.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.develop.id}"
}

# Create a subnet to launch our instances into
resource "aws_subnet" "develop" {
  vpc_id                  = "${aws_vpc.develop.id}"
  cidr_block              = "10.20.10.0/24"
  map_public_ip_on_launch = true

  tags {
    Name = "EGAR-DEVELOPER-Subnet"
    project = "EGAR"
    egar = "subnet"
  }
}

# Our default security group to access
# the instances over SSH and HTTP
resource "aws_security_group" "develop" {
  name        = "terraform_example"
  description = "EGAR Test Security Group"
  vpc_id      = "${aws_vpc.develop.id}"

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
    Name = "EGAR-DEVELOPER-SecurityGrp"
    project = "EGAR"
    egar = "secgrp"
  }
}

