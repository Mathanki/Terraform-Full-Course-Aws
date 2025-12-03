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
    #Task 6: Set(string)
    validation {
    # The condition uses the 'contains' function with the 'allowed_region' set.
    # It checks if the input 'var.region' is present in the set.
    condition     = contains(var.allowed_region, var.region)
    # The error message to display if the condition is false.
    error_message = "The specified region (${var.region}) is not in the allowed list: [${join(", ", var.allowed_region)}]. Deployment is restricted to allowed regions only."
  }
}

# number type       
variable "instance_count" {
    type = number
    description = "the number of ec2 instances to create"
    default = 1 
}

# bool type
variable "enable_monitoring" {
    type = bool
    description = "enable detailed monitoring for ec2 instances"
    default = false
}

variable "associate_public_ip" {
    type = bool
    description = "associate public ip to ec2 instance"
    default = true
}

# List type - IMPORTANT: Allows duplicates, maintains order
variable "allowed_cidr_blocks" {
    type = list(string)
    description = "list of allowed cidr blocks for security group"
    default     = ["10.0.0.0/16", "192.168.1.0/24", "172.16.1.0/24"]
}
variable "allowed_instance_types" {
    type = list(string)
    description = "list of allowed ec2 instance types"
    default = ["t2.micro", "t2.small", "t3.micro"]
}

# Set type - IMPORTANT: No duplicates allowed, order doesn't matter
variable "allowed_region" {
    type = set(string)
    description = "set of availability zones (no duplicates)"
    default = ["us-east-1", "us-west-2", "eu-west-1"]
}

# Map type - IMPORTANT: Key-value pairs, keys must be unique
variable "instance_tags" {
    type = map(string)
    description = "tags to apply to the ec2 instances"
    default = {
        "Environment" = "dev"
        "Name" = "dev-Instance"
        "created_by" = "terraform"
    }
}

# Tuple type - IMPORTANT: Fixed length, each position has specific type
variable "ingress_values" {
    type = tuple([number, string, number])
    description = "Network configuration (from_port,  ip_protocol, to_port )"
    default = [ 443, "tcp", 443 ]
}

# Object type - IMPORTANT: Named attributes with specific types
variable "server_config" {
    type = object({
        region = string
        monitoring = bool
        instance_count = number
    })
    description = "Complete server configuration object"
    default = {
        region = "us-east-1"
        monitoring = true
        instance_count = 1
    }
}

variable "ingress_rules" {
   type = list(object({
    from_port = number
    to_port = number
    protocol = string
    cidr_blocks = list(string)
   }))
   default = [
    {
      from_port = 80
      to_port = 80
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      from_port = 443
      to_port = 443
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
   ]
}