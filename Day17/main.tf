
#IAM Instance Profile (The container to deliver the role to EC2)
resource "aws_iam_instance_profile" "eb_ec2_profile" {
  name = "${var.app_name}-eb-ec2-profile"
  role = aws_iam_role.eb_ec2_role.name
  tags = var.tags
}

# Elastic Beanstalk Application
resource "aws_elastic_beanstalk_application" "app" {
  name        = var.app_name
  description = "Blue-Green Deployment Demo Application"
  tags = var.tags
}

# S3 Bucket for application versions
resource "aws_s3_bucket" "app_versions" {
  bucket = "${var.app_name}-versions-${data.aws_caller_identity.current.account_id}"
  tags = var.tags
}

# Block public access to S3 bucket
resource "aws_s3_bucket_public_access_block" "app_versions" {
  bucket = aws_s3_bucket.app_versions.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Data source for current AWS account
data "aws_caller_identity" "current" {}