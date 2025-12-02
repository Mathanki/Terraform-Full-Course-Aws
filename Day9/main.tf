resource "aws_security_group" "application_sg" {
  name        = "app-security-group"
  description = "Security group for application servers"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP from anywhere"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS from anywhere"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(
    var.resource_tags,
    {
      Name = "App Security Group"
      Demo = "replace_triggered_by"
    }
  )
}

resource "aws_instance" "web_server" {
  ami                    = "ami-0ff8a91507f77f867"
  instance_type          = var.allowed_instance_types[0]
  region                 = tolist(var.allowed_regions)[0]
  vpc_security_group_ids = [aws_security_group.application_sg.id]

  tags = var.resource_tags

  lifecycle {
    # Lifecycle Rule: Create new instance before destroying the old one
    # This ensures zero downtime during instance updates (e.g., changing AMI or instance type)
    create_before_destroy = true

    # Instruct Terraform to ignore any changes made to the 'tags' attribute
    # in the cloud provider after the initial creation.
    ignore_changes = [tags]

    # Lifecycle Rule: Replace instance when security group changes
    # This ensures the instance is recreated with new security rules
    replace_triggered_by = [
      aws_security_group.application_sg.id
    ]
  }
}

# Get current AWS region
data "aws_region" "current" {}

resource "aws_s3_bucket" "demo-sample-bucket" {
  for_each = var.bucket_names
  bucket   = "${each.value}-${var.environment}"

  tags = var.resource_tags

  # Lifecycle Rule: Prevent accidental deletion of this bucket
  # Terraform will throw an error if you try to destroy this resource
  # To delete: Comment out prevent_destroy first, then run terraform apply
  lifecycle {
    #prevent_destroy = true  # COMMENTED OUT TO ALLOW DESTRUCTION

    # Lifecycle Rule: Validate region before creating resource
    # This prevents resource creation in unauthorized regions
    precondition {
      condition     = contains(var.allowed_regions, data.aws_region.current.id)
      error_message = "ERROR: This resource can only be created in allowed regions: ${join(", ", var.allowed_regions)}. Current region: ${data.aws_region.current.id}"
    }

    # Lifecycle Rule: Validate bucket has required tags after creation
    # This ensures compliance with organizational tagging policie
    postcondition {
      condition     = contains(keys(self.tags), "Environment")
      error_message = "ERROR: Bucket must have an 'Environment' tag!"
    }
  }

}
