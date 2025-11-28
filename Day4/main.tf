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

#Create VPC
resource "aws_vpc" "demo_vpc"{
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "My_demo_vpc"
  }
}

#Create S3 Bucket
resource "aws_s3_bucket" "first_demo_bucket"{
  bucket = "tech-demo-mathanki-bucket-1-${aws_vpc.demo_vpc.id}"

  tags = {
    Name        = "My bucket 1.0"
    Environment = "Dev"
  }
}

