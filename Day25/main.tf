variable "vpc_id" {}

data "aws_vpc" "selected" {
  id = var.vpc_id
}

resource "aws_security_group" "demo_sg" {
  name                   = "manually-create-sg"
  region                 = "us-east-1"
  vpc_id                 = data.aws_vpc.selected.id
  description = "launch-wizard-2 created 2025-12-29T19:09:41.521Z"
  # Standard Outbound Rule (Allow all)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH Access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS Access
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP Access
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "demo" {
  ami                                  = "ami-0ecb62995f68bb549"
  instance_type                        = "t3.micro"
  region                               = "us-east-1"
  security_groups                      = [aws_security_group.demo_sg.name]
  tags = {
    Name = "manually-created-instance"
    MangedBy="Terraform"
  }
  vpc_security_group_ids      = [aws_security_group.demo_sg.id]
  
}