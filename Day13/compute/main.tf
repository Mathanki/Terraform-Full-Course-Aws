# Data source to get the existing VPC
data "aws_vpc" "shared-fetch-vpc" {
  filter {
    name   = "tag:Name"
    values = ["shared-network-vpc"]
  }
}

# Data source to get the existing subnet
data "aws_subnet" "shared-fetch-subnet" {
  filter {
    name   = "tag:Name"
    values = ["shared-primary-subnet"]
  }
  vpc_id = data.aws_vpc.shared-fetch-vpc.id  # ← Using first data source!
}

# Data source for the latest Amazon Linux 2 AMI
data "aws_ami" "amazon_server_ami_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


resource "aws_instance" "server1" {
    ami = data.aws_ami.amazon_server_ami_linux_2.id
    instance_type = "t2.micro"
    subnet_id = data.aws_subnet.shared-fetch-subnet.id
    tags = {
        Environment = "dev"
    }
}