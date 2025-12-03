locals {
    instance_ids = aws_instance.server1[*].id
} 