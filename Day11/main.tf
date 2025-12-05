resource "aws_s3_bucket" "demo" {
  bucket = local.formatted_bucket_name

  tags = merge(var.default_tags, var.environment_tags)
}
