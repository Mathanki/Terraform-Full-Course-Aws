
output "ec2_id" {
    value = aws_instance.web_server[*].id
}