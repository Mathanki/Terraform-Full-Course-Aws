# String type
variable "environment" {
    type = string
    description = "the environment type"
    default = "dev"
    
}
variable "region" {
    type = string
    description = "the aws region" 
    default = "us-east-1"
}

variable "bucket_names_list" {
  description = "List of S3 bucket names list"
  type        = list(string)
  default     = ["bucket-one-day-8-12345", "bucket-two-day-8-12345", "bucket-three-day-8-12345"]
}

variable "bucket_names_set" {
  description = "List of s3 bucket names set"
  type = set(string)
  default = ["bucket-one-day-8-12346", "bucket-two-day-8-12347", "bucket-three-day-8-12348"]  
}