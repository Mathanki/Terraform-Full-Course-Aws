terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
  backend "s3" {
    bucket         = "tech-demo-mathanki-terraform-state"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    use_lockfile   = true
  }
}

# The default provider configuration (for S3, Route 53, etc.)
provider "aws" {
  region = var.aws_region
}

# The explicit alias required for ACM/CloudFront (MUST be us-east-1)
provider "aws" {
  alias  = "us_east_1" # <--- Must be a string literal, not a variable
  region = "us-east-1"
}