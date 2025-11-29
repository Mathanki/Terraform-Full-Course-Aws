
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

