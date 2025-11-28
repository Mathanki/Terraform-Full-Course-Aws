terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
  backend "s3" {
    bucket         = "tech-demo-mathanki-terraform-state" # MUST be the name of the bucket you created
    key            = "dev/terraform.tfstate" # The path/key for THIS project's state
    region         = "us-east-1"
    encrypt        = true
    use_lockfile   = true # This enables S3 Native Locking
    # No dynamodb_table argument is needed!
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

variable "environment" {
    default = "dev"
    type = string
}

variable "region" {
    default = "us-east-1"
    type = string 
}

variable "bucket-name" {
    default = "tdm-bucket-1"
  
}

locals {
  bucket_name="${var.bucket-name}-${var.environment}"
  vpc_name="${var.environment}-vpc"
}

#Create VPC
resource "aws_vpc" "demo_vpc"{
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"
  region = var.region

  tags = {
    Name = local.vpc_name
    Environment = var.environment
  }
}

#Create S3 Bucket
resource "aws_s3_bucket" "first_demo_bucket"{
  bucket = local.bucket_name

  tags = {
    Name        = local.bucket_name
    Environment = var.environment
  }
}

#Create EC2 Instance
resource "aws_instance" "web_server" {
  ami           = "resolve:ssm:/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
  instance_type = "t2.micro"
  region = var.region

  tags = {
    Name = "${var.environment}-ec2-instance"
    Environment = var.environment
  }
}

output "vpc_id" {
    value = aws_vpc.demo_vpc.id
}

output "ec2_id" {
    value = aws_instance.web_server.id
}

