output "vpc_id" {
    value = aws_vpc.demo_vpc.id
}

output "ec2_id" {
    value = aws_instance.web_server.id
}