resource "aws_vpc" "shared-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "shared-network-vpc"  # ← This tag is important!
  }
}

resource "aws_subnet" "shared-subnet" {
  vpc_id     = aws_vpc.shared-vpc.id
  cidr_block = "10.0.1.0/24"
  tags = {
    Name = "shared-primary-subnet"  # ← This tag is important!
  }
}