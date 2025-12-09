variable "aws_region" {
  description = "The AWS region to create resources in."
  type        = string
  default     = "us-east-1"
}

variable "bucket_prefix" {
  description = "Prefix for the S3 bucket name."
  type        = string
  default     = "cloudcoachguru.in"
}

variable "bucket_name" {
  default = "cloudcoachguru.in"
}

variable "domain_name" {
  description = "The domain name for the certificate (e.g., example.com)"
  type        = string
  default = "cloudcoachguru.in"
}

variable "common_tags" {
  description = "Common tags to apply to resources"
  type        = map(string)
  default = {
   ManagedBy = "Terraform"
   Project   = "Static Website"
  }
}

