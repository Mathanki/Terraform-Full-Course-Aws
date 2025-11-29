
#Create S3 Bucket
resource "aws_s3_bucket" "first_demo_bucket"{
  bucket = local.bucket_name

  tags = {
    Name        = local.bucket_name
    Environment = var.environment
  }
}