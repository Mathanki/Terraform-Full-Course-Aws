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
