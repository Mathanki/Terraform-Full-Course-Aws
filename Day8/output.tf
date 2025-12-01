//TASK-3 outputs for bucket1 and bucket2 names and ids 
output "bucket1_ids" {
  description = "List of all the bucket1 ids"
  value       = [for b in aws_s3_bucket.bucket1 : b.id]
}

output "bucket1_names" {
  description = "List of all the bucket1 names"
  value       = [for b in aws_s3_bucket.bucket1 : b.bucket]
}

# Using for loop to get bucket id from bucket2
output "bucket2_ids" {
  description = "List of all the bucket2 ids"
  value       = [for b in aws_s3_bucket.bucket2 : b.id]
}

# Using for loop to get bucket names from bucket2
output "bucket2_names" {
  description = "List of all the bucket2 names"
  value       = [for b in aws_s3_bucket.bucket2 : b.bucket]
}

# Creating a map output with bucket names and ARNs
output "bucket2__id_arn" {
  description = "List of all the bucket2 id,name"
  value = {
    for key,b in aws_s3_bucket.bucket2 :
    key => {
      id  = b.id
      arn = b.arn
    }
  }
}

