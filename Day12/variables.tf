# String type
variable "environment" {
  type        = string
  description = "the environment type"
  default     = "dev"

}

variable "region" {
  type        = string
  description = "the aws region"
  default     = "us-east-1"
  validation {
    # Pattern: two letters, hyphen, word, hyphen, number.
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]{1}$", var.region))
    error_message = "The AWS region must be in the standard format (e.g., us-east-1)."
  }
}

# number type       
variable "instance_count" {
  type        = number
  description = "the number of ec2 instances to create"
  default     = 1
}


# List type - IMPORTANT: Allows duplicates, maintains order
variable "allowed_cidr_blocks" {
  type        = list(string)
  description = "list of allowed cidr blocks for security group"
  default     = ["10.0.0.0/16", "192.168.1.0/24", "172.16.1.0/24"]
}
variable "allowed_instance_types" {
  type        = list(string)
  description = "list of allowed ec2 instance types"
  default     = ["t2.micro", "t2.small", "t3.micro"]
}

# Set type - IMPORTANT: No duplicates allowed, order doesn't matter
variable "allowed_region" {
  type        = set(string)
  description = "set of availability zones (no duplicates)"
  default     = ["us-east-1", "us-west-2", "eu-west-1"]
}

# Map type - IMPORTANT: Key-value pairs, keys must be unique
variable "instance_tags" {
  type        = map(string)
  description = "tags to apply to the ec2 instances"
  default = {
    "Environment" = "dev"
    "Name"        = "dev-Instance"
    "created_by"  = "terraform"
  }
}

# Tuple type - IMPORTANT: Fixed length, each position has specific type
variable "ingress_values" {
  type        = tuple([number, string, number])
  description = "Network configuration (from_port,  ip_protocol, to_port )"
  default     = [443, "tcp", 443]
}

# Object type - IMPORTANT: Named attributes with specific types
variable "server_config" {
  type = object({
    region         = string
    monitoring     = bool
    instance_count = number
  })
  description = "Complete server configuration object"
  default = {
    region         = "us-east-1"
    monitoring     = true
    instance_count = 1
  }
}

variable "ingress_rules" {
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}

variable "project_name" {
  default = "Project ALPHA Resource"
}

variable "default_tags" {
  default = {
    company    = "TechAlpha"
    managed_by = "Terraform"
  }
}

variable "environment_tags" {
  default = {
    environment = "dev"
    cost_center = "1001"
  }
}

variable "bucket_name" {
  # make the name complex - not fit in aws standards
  default = "Tech alpha demo is the bucket name!!!!"
}

variable "allowed_ports" {
  default = "22,80,443"
}

variable "instance_sizes" {
  default = {
    dev     = "t2.micro"
    staging = "t2.small"
    prod    = "t2.medium"
  }
}

variable "ip_range" {
  description = "A valid CIDR range for the VPC."
  type        = string
  default     = "10.0.0.0/16"
  validation {
    # Checks if the cidrhost function can successfully process the input string.
    condition     = can(cidrhost(var.ip_range, 0))
    error_message = "The ip_range must be a valid CIDR block (e.g., 10.0.0.0/16)."
  }
}

variable "instance_type" {
  description = "The EC2 instance type to use."
  type        = string
  default     = "t2.micro"
  validation {
    # Checks if the input is one of the allowed types.
    condition     = contains(["t2.micro", "t3.small", "t3a.small"], var.instance_type)
    error_message = "The instance_type must be t2.micro, t3.small, or t3a.small."
  }
  # validation 1 - length
  validation {
   condition = length(var.instance_type) >= 2 && length(var.instance_type) <= 20
   error_message = "Instance type must be between 2 and 20 characters long"
  }
  # validation 2 - allowed values only t2 and t3 instances
  validation {
    # so here we can use regular expression (regex)
    condition = can(regex("^t[2-3]\\.", var.instance_type))
    error_message = "Instance type must be t2 or t3"
  }
}

variable "bucket_resource_name" {
  description = "A name for the resource."
  type        = string
  default     = "proj-A-bucket1-prod"
  validation {
    # Ensure the name starts with "proj-A-" AND ends with "-prod"
    condition     = startswith(var.bucket_resource_name, "proj-A-") && endswith(var.bucket_resource_name, "-prod")
    error_message = "Bucket name must start with 'proj-A-' and end with '-prod' (e.g., proj-A-webserver-prod)."
  }
}

variable "environment_settings" {
  default = {
    "prod" : {"region" : "us-east-1", "instance_count" : 5  },
    "staging" : {"region" : "us-west-2", "instance_count" : 3 },
    "dev" : {"region" : "eu-central-1", "instance_count" : 1 }
  }
}

variable supported_zones {
  default= ["us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d"]
} 

variable "backup_name" {
    default = "daily_backup"
    validation {
        condition = endswith(var.backup_name, "_backup")
        error_message = "Backup name must end with '_backup'"
    }
}

variable "credentials" {
  default = "xyz123"
  sensitive = true
}

variable "monthly_cost" {
  default = [-50,300,12,-10,21]
}
