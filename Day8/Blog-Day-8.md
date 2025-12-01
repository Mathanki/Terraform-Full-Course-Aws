

# Day 08: Terraform Meta-Arguments – Complete Guide | #30DaysOfAWSTerraform


Meta-arguments are one of the most powerful features in Terraform. They allow resources to become more dynamic, more controlled, and easier to manage at scale. Day 08 focuses entirely on understanding these meta-arguments and using them effectively with real-world infrastructure.

This guide provides a complete breakdown of **count, for\_each and depends\_on** along with practical advice for each.

Meta-arguments are special settings that can be added to any resource or module block to modify how Terraform creates, manages, or destroys infrastructure.

They don’t define _what_ is created—but rather _how_ it is created.

They help achieve:

-   Resource scaling
    
-   Iteration over inputs
    
-   Explicit dependency management
    
-   Advanced lifecycle protection
    
-   Multi-provider deployments
    

Let’s explore each of these in detail:

1.  ### count – Create Resources with Numeric Indexing
    
    count creates multiple instances of a resource based on a number
    
    When to use count:
    
    -   When resources can be identified by index
        
    -   When the number of instances is based on a simple condition
        
    -   When a list input drives resource creation
        

**Example:**

```
variable "bucket_names_list" {
  description = "List of S3 bucket names list"
  type        = list(string)
  default     = ["bucket-one-day-8-12345", "bucket-two-day-8-12345", "bucket-three-day-8-12345"]
}

#Create S3 bucket 
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
```

The **length()** function is used to determine the number of elements in the list variable var.bucket\_names\_list.

Since the list contains three bucket names, length() returns 3.

Result: Terraform will create three separate aws\_s3\_bucket resources, internally addressed as aws\_s3\_bucket.bucket1\[0\], aws\_s3\_bucket.bucket1\[1\], and aws\_s3\_bucket.bucket1\[2\].

**count.index** is a special variable available only when count is used. It holds the current numerical index of the resource instance being created (0, 1, or 2). It used to access each name in the list.

2.  ### for\_each – Create Resources from Maps/Sets
    
    for\_each is more powerful and more predictable than count
    
    When to use for\_each:
    
    -   When resource names must be meaningful
        
    -   When working with maps or sets
        
    -   When you want stable resource addressing
        

**Example:**

```
variable "bucket_names_set" {
  description = "List of s3 bucket names set"
  type = set(string)
  default = ["bucket-one-day-8-12346", "bucket-two-day-8-12347", "bucket-three-day-8-12348"]  
}

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
```

for\_each = var.bucket\_names\_set: Terraform will loop through every unique string in the bucket\_names\_set. Result: Since there are three strings in the set, three separate aws\_s3\_bucket resources will be created.

When iterating over a set, the for\_each loop exposes the following special object: each.value: This holds the current element from the set being processed. In thecode, each.value is used to set the attributes of the bucket: bucket = each.value: This dynamically assigns the current string from the set as the S3 bucket name.

3.  ### depends\_on – Explicit Dependencies
    
    Terraform automatically infers dependencies—however, some cases require manual control.
    
    Use depeds\_on when:
    
    -   A resource must not be created before another
        
    -   Null resources or external data sources must wait
        
    -   Modules depend on external resources
        

**Example:**

```
resource "aws_s3_bucket" "bucket1" {
  bucket = "bucket1"
}

resource "aws_s3_bucket" "bucket2" {
  bucket = "bucket2"
  depends_on = [aws_s3_bucket.bucket1]
}
```

In the example above, bucket2 will not be created until bucket1 has been successfully created.

## Pratical Example: Creating mutiple resourses ans output

A practical demonstration helps solidify how meta-arguments work in real infrastructure scenarios. In this example, resources are created using both `for_each` and `count`, allowing multiple S3 buckets to be provisioned from a predefined collection. Once the resources are deployed, the configuration also includes outputs that return the bucket names and IDs, showcasing how Terraform can dynamically expose values from iterated resources.

Sourse code:

[versions.tf](http://versions.tf/)

```
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

# Configure the AWS Provider
provider "aws" {
  region = var.server_config.region

}
```

[variables.tf](http://variables.tf/)

```
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
```

[main.tf](http://main.tf/)

```

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
```

[output.tf](http://output.tf/)

```
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
```

In this example, the configuration demonstrates how Terraform handles resource iteration and dynamic outputs. The S3 buckets are provisioned using for\_each, ensuring predictable naming and stable keys. After deployment, five outputs are generated.

## Conclusion

Meta-arguments significantly enhance how infrastructure is managed in Terraform. They bring flexibility, clarity, and fine-grained control to any configuration. Whether it’s scaling resources, ensuring proper dependency ordering, or applying lifecycle protections, meta-arguments play a critical role in building reliable and maintainable infrastructure-as-code.

For this blog, the focus remains on three foundational meta-arguments—`count`, `for_each`, and `depends_on`—as they form the core of Terraform’s resource iteration and dependency management capabilities. The remaining meta-arguments such as `lifecycle`, `provider`, and advanced transformation features will be covered in the next part of this series.

Mastering these concepts lays a strong foundation for advanced Terraform workflows and real-world AWS deployments.

## Reference

https://www.youtube.com/watch?v=XMMsnkovNX4&list=PLl4APkPHzsUXcfBSJDExYR-a4fQiZGmMp&index=9
