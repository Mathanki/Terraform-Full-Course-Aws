
# Day 10: Terraform Dynamic Blocks, Conditional Expressions, and Splat Expressions – #30DaysOfAWSTerraform


Infrastructure as Code becomes more powerful when configurations adapt automatically to data, conditions, and reusable patterns. On Day 10, the focus shifts to three features that bring flexibility and intelligence into Terraform: **Conditional Expressions, Dynamic Blocks, and Splat Expressions**.

These concepts help reduce repetitive code, make decisions during resource creation, and extract values from complex data structures more efficiently. Mastering them contributes to writing clean, scalable, and automation-ready Terraform configurations.

## Conditional Expressions

Conditional expressions act as decision-makers inside Terraform configurations.

They evaluate a condition and return one of two values based on whether the condition is **true** or **false**.

Syntax:

```
condition ? true_value : false_value
```

UseCases:

-   Enabling or disabling optional resources
    
-   Selecting instance types based on environment
    
-   Applying tags conditionally
    
-   Creating count-based resources conditionally
    

Example:

```
resource "aws_instance" "server1" {
  ami = "ami-0c55b159cbfafe1f0"
  instance_type = var.environment == "dev" ? "t2.micro" : "t3.micro"

  count = 2
  tags = {
    Name = "server1"
    Env  = var.environment
  }
}
```

The conditional expression acts as a single point of decision for setting the instance type. By using the conditional expression, the entire aws\_instance block (ami, count, tags) remains identical across all environments, and only the specific parameter (instance\_type) changes based on the input variable. This makes the code much easier to maintain.

The **terraform plan** command is main tool for verifying what infrastructure changes will occur.

```
terraform plan -var 'environment=prod'|grep "instance_type"
```

When run with environment='pod’ output shows as:

![](day-10-terraform/25dd109e-567a-45c0-bdbe-c172e90ac691.png)

This ensures the configuration automatically adjusts to each environment.

## Dynamic Blocks

Dynamic blocks allow Terraform to create **repeatable nested blocks** programmatically.

This is especially useful when dealing with resource arguments that accept multiple nested attributes.

Without dynamic blocks, developers often end up writing repetitive code. Dynamic blocks help generate those repeated structures based on input data.

When They Are Useful:

-   Multiple security group rules
    
-   Multiple EBS volumes attached to an EC2 instance
    
-   IAM policy statements
    
-   Listener rules for load balancers
    

Syntax:

```
resource "resource_type" "resource_name" {
  # ... other static arguments ...

  dynamic "NESTED_BLOCK_NAME" {
    for_each = COLLECTION_TO_ITERATE
    content {
      # Arguments for the nested block are defined here.
      # You must use the iterator to access the current element's data.
      nested_block_argument_1 = ITERATOR_NAME.value.attribute_1
      nested_block_argument_2 = ITERATOR_NAME.key
    }
  }
}
```

Example:

When defining a security group with multiple ingress rules, writing each rule manually can quickly become repetitive and difficult to maintain. Terraform’s **dynamic block** feature solves this by allowing the configuration to loop through a variable containing the desired rules and generate each ingress block automatically.

```
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

resource "aws_security_group" "server-sg" {
  name        = "my-sg"
  description = "my-sg"

  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }
}
```

This method makes code highly reusable and maintainable. If wanted to add a rule for port 21, only need to add a new object to the var.ingress\_rules list, don't need to touch the aws\_security\_group resource block at all.

This helps maintain clean, efficient configurations by removing repetitive code and allowing ingress rules to be added or updated with minimal effort.

## Splat Expressions

Splat expressions extract values from lists or collections **efficiently and cleanly**.

They are used when:

-   A resource uses `count` or `for_each`
    
-   Values need to be gathered into a simple list
    
-   Outputs require structured extraction
    

There are two main forms of the Splat Expression syntax: `*` (Asterisk Splat) and `[*]` (Bracket Splat).

1.  **The Asterisk Splat (\*)**
    
    The asterisk splat is used to extract a list of attributes from a collection of resources (like those created with count or for\_each) or a list of complex objects.
    
    Syntax:
    
    ```
     Collection. * .attribute_name
    ```
    

Example:

```
resource "aws_instance" "server1" {
  count = 3
  # ... other config ...
}

# The Splat Expression:
output "instance_ids" {
  value = aws_instance.server1.*.id
}
```

aws\_instance.server1.\*.id will return a list of the IDs for all three instances

2.  **The Bracket Splat (\[\*\])**
    
    The bracket splat is a newer, more flexible alternative. It is primarily used with list or tuple values where you need to extract attributes but also want to **filter out any items that are null or not yet known**.
    
    Syntax:
    
    ```
     list_of_tuble[*] .attribute_name
    ```
    

Example:

```
resource "aws_instance" "server1" {
  ami = "ami-0c55b159cbfafe1f0"

  #   instance_type = "t2.micro"
  instance_type = var.environment == "dev" ? "t2.micro" : "t3.micro"

  count = 2
  tags = {
    Name = "server1"
    Env  = var.environment
  }
}

locals {
    instance_ids = aws_instance.server1[*].id
} 

output "all_instance_ids" {
    value = local.instance_ids
}
```

This technique simplifies gathering values from multiple instances by automatically pulling the required data without manual indexing or repeated code.

## Conclusion

Terraform features such as Conditional Expressions, Dynamic Blocks, and Splat Expressions bring powerful simplicity to infrastructure-as-code workflows. These capabilities enable configurations that adapt to different environments, reduce duplication, and automate repetitive structures. Whether defining scalable security group rules, tailoring resources based on environment-specific needs, or retrieving values from multiple resources, these expressions contribute to cleaner, more maintainable Terraform code.

Integrating these techniques into Terraform projects leads to a more streamlined, efficient, and future-ready infrastructure setup.

## Reference

https://www.youtube.com/watch?v=R4ShnFDJwI8&list=PLl4APkPHzsUXcfBSJDExYR-a4fQiZGmMp&index=11
