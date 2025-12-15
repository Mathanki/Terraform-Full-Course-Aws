terraform {
  backend "s3" {
    bucket = "tech-demo-mathanki-terraform-state"
    key    = "dev/terraform-day19.tfstate"
    region = "us-east-1"
  }
}