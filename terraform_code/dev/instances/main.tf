#----------------------------------------------------------
# ACS730 - Week 3 - Terraform Introduction
#
# Build EC2 Instances and pull Docker images from ECR
#
#----------------------------------------------------------

# Define the provider
provider "aws" {
  region = "us-east-1"
}

# Data source for AMI id
data "aws_ami" "latest_amazon_linux" {
  owners      = ["amazon"]
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Data source for availability zones in us-east-1
data "aws_availability_zones" "available" {
  state = "available"
}

# Data block to retrieve the default VPC id
data "aws_vpc" "default" {
  default = true
}

# Define tags locally
locals {
  default_tags = {
    "Owner"   = "Dockerintro"
    "Project" = "CLO835"
    "env"     = "dev"
  }
}

# ECR Repository
resource "aws_ecr_repository" "assignment1" {
  name                 = "assignment1"
  image_tag_mutability = "MUTABLE"  # or "IMMUTABLE"
  
  # Add tags to the repository
  tags = {
    "Name" = "assignment1"
    "Owner" = local.default_tags["Owner"]
    "Project" = local.default_tags["Project"]
    "env" = local.default_tags["env"]
  }
}

# Reference subnet provisioned by 01-Networking 
resource "aws_instance" "my_amazon" {
  ami                         = data.aws_ami.latest_amazon_linux.id
  instance_type               = "t2.micro" # Adjust as needed
  key_name                    = aws_key_pair.my_key.key_name
  vpc_security_group_ids      = [aws_security_group.my_sg.id]
  associate_public_ip_address  = true

  # Adding user_data to integrate with ECR
  # user_data = <<-EOF
  #             #!/bin/bash
  #             # Install Docker
  #             sudo amazon-linux-extras install docker -y
  #             sudo service docker start
  #             sudo usermod -aG docker ec2-user

  #             # ECR Login
  #             aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin ${aws_ecr_repository.assignment1.repository_url}

  #             # Pull Docker Image from ECR
  #             docker pull ${aws_ecr_repository.assignment1.repository_url}:latest

  #             # Run the Docker container
  #             docker run -d -p 80:80 ${aws_ecr_repository.assignment1.repository_url}:latest
  #             EOF

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    "Name" = "Amazon-Linux-Instance"
    "Owner" = local.default_tags["Owner"]
    "Project" = local.default_tags["Project"]
    "env" = local.default_tags["env"]
  }
}

# Adding SSH key to Amazon EC2
resource "aws_key_pair" "my_key" {
  key_name   = "week1-dev"  # Change this to your key pair name
  public_key = file("week1-dev.pub")  # Update the path to your public key
}

# Security Group
resource "aws_security_group" "my_sg" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description      = "SSH from everywhere"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    "Name" = "allow_ssh"
  }
}

# Elastic IP
resource "aws_eip" "static_eip" {
  instance = aws_instance.my_amazon.id
  tags = {
    "Name" = "static-eip"
  }
}
