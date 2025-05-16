terraform {
  backend "remote" {
    organization = "nafiz_dev"

    workspaces {
      name = "vpc-workspace"
    }
  }
}

provider "aws" {
  region = "ap-southeast-1"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "4.0.0"

  name = "my-vpc-porodhi"
  cidr = "10.0.0.0/16"

  azs            = ["ap-southeast-1a"]
  public_subnets = ["10.0.1.0/24"]

  enable_dns_hostnames = true
  enable_dns_support   = true

  map_public_ip_on_launch = true

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

resource "aws_security_group" "ec2_sg" {
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ec2-sg"
  }
}

resource "aws_key_pair" "main" {
  key_name   = "id_rsa"
  public_key = var.ssh_public_key
}

resource "aws_instance" "ec2" {
  ami           = "ami-060e277c0d4cce553"  # Example Ubuntu AMI
  instance_type = "t2.micro"
  subnet_id     = module.vpc.public_subnets[0]
  key_name      = aws_key_pair.main.key_name

  tags = {
    Name = "public-ec2-instance"
  }

 
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
}