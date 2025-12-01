
#Create S3 bucket list
resource "aws_s3_bucket" "bucket1" {
  count = length(var.bucket_names_list)
  bucket = var.bucket_names_list[count.index]
 
  region = var.region

  tags = {
    Name        = var.bucket_names_list[count.index]
    Environment = var.environment
    Index       = count.index
    BucketType  = "count-example"
    ManagedBy   = "terraform"
  }
}

#Create S3 bucket set
resource "aws_s3_bucket" "bucket2" {
  for_each = var.bucket_names_set
  bucket = each.value

  region = var.region

  tags = {
    Name        = each.value
    Environment = var.environment
    BucketType  = "foreach-example"
    ManagedBy   = "terraform"
  }
}


