# Specify the provider and access details
provider "aws" {
  region = "eu-west-2"
}

# Create a VPC to launch our instances into
resource "aws_vpc" "drone" {
  cidr_block = "10.21.0.0/16"

  tags {
    Name = "EGAR-DRONE-VPC"
    project = "EGAR"
    egar = "vpc"
  }
}

# Create an internet gateway to give our subnet access to the outside world
resource "aws_internet_gateway" "drone" {
  vpc_id = "${aws_vpc.drone.id}"

  tags {
    Name = "EGAR-DRONE-GW"
    project = "EGAR"
    egar = "gw"
  }
}

# Grant the VPC internet access on its main route table
resource "aws_route" "internet_access" {
  route_table_id         = "${aws_vpc.drone.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.drone.id}"
}

# Create a subnet to launch our instances into
resource "aws_subnet" "drone" {
  vpc_id                  = "${aws_vpc.drone.id}"
  cidr_block              = "10.21.10.0/24"
  map_public_ip_on_launch = true

  tags {
    Name = "EGAR-DRONE-Subnet"
    project = "EGAR"
    egar = "subnet"
  }
}

# Our default security group to access
# the instances over SSH and HTTP
resource "aws_security_group" "drone" {
  name        = "terraform_example"
  description = "EGAR Drone Security Group"
  vpc_id      = "${aws_vpc.drone.id}"

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
    Name = "EGAR-DRONE-SecurityGrp"
    project = "EGAR"
    egar = "secgrp"
  }
}

resource "aws_instance" "drone" {
  ami           = "ami-b2b55cd5"
  instance_type = "t2.medium"
  key_name = "EGAR"
  root_block_device {
    volume_type="gp2"
    volume_size="20"
    delete_on_termination = "true"
    }
  subnet_id = "${aws_subnet.drone.id}"
  vpc_security_group_ids = ["${aws_security_group.drone.id}"]
  tags {
    Name = "EGAR-DRONE-SERVER"
    project = "EGAR"
    egar = "ec2"
    Owner = "Bill"
  }

  connection {
    type = "ssh"
    user = "ec2-user"
    private_key = "${file("EGAR.pem")}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum -y install docker",
      "sudo curl -L https://github.com/docker/compose/releases/download/1.21.2/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose",
      "sudo chmod 775 /usr/local/bin/docker-compose",
      "sudo chkconfig docker on",
      "sudo service docker start",
      "sudo yum -y install git",
      "cd",
      "git clone https://github.com/billhartcivica/drone-config.git"
      ]
  }
}

resource "aws_eip" "ip" {
  instance = "${aws_instance.drone.id}"
}

