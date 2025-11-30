

# Day 7: Type Constraints in


In **Day 5**, we explored Terraform variables _based on purpose_—Input, Output, and Locals.

Today, for **Day 7**, we shift our focus to something equally important but often confusing for beginners.

## Variables Based on Values in Terraform

Terraform classifies variables not just by their purpose but also by the **type of data** they hold. These are known as **Value-Based Types**, and they help Terraform understand the structure and behavior of the data you're working with.

Correctly choosing and defining these types makes your configurations more predictable, reliable, and easier to debug.

## Primitive Types

Primitive types are the simplest and most commonly used variable types in Terraform. Primitive types are powerful because they enforce strict validation and avoid unexpected results especially when performing comparisons or arithmetic operations.There are exactly three of them:

1.  **string**
    
    Used for text-based values.
    
    ```
     # string type
     variable "environment" {
         type = string
         description = "the environment type"
         default = "dev" 
     }
    ```
    
2.  **number**
    
    Represents numeric values—integer or floating point.
    
    ```
     # number type       
     variable "instance_count" {
         type = number
         description = "the number of ec2 instances to create"
         default = 1 
     }
    ```
    
3.  **bool**
    
    Represents true or false.
    
    ```
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
    ```
    
    ## **Complex Types**
    
    When need group or structure data, Terraform offers **complex types**. These are extremely useful in real-world infrastructure automation
    
    1.  list
        
        An ordered sequence of values of the same type.
        
        ```
         # List type - IMPORTANT: Allows duplicates, maintains order
         variable "allowed_cidr_blocks" {
             type = list(string)
             description = "list of allowed cidr blocks for security group"
             default = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
         }
         variable "allowed_instance_types" {
             type = list(string)
             description = "list of allowed ec2 instance types"
             default = ["t2.micro", "t2.small", "t3.micro"]
             # Order matters: index 0 = t2.micro, index 1 = t2.small
         }
        ```
        
    2.  set
        
        A collection of unique values—order doesn’t matter.
        
        ```
         # Set type - IMPORTANT: No duplicates allowed, order doesn't matter
         variable "availability_zones" {
             type = set(string)
             description = "set of availability zones (no duplicates)"
             default = ["us-east-1a", "us-east-1b", "us-east-1c"]
         }
        ```
        
    3.  map
        
        A key-value pair structure similar to dictionaries.
        
        ```
         # Map type - IMPORTANT: Key-value pairs, keys must be unique
         variable "instance_tags" {
             type = map(string)
             description = "tags to apply to the ec2 instances"
             default = {
                 "Environment" = "dev"
                 "Project" = "terraform-course"
                 "Owner" = "devops-team"
             }
         }
        ```
        
    4.  object
        
        A structured dictionary where each attribute has a defined type.
        
        ```
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
        ```
        
    5.  tuple
        
        A fixed-length list with elements of different types.
        
        ```
         # Tuple type - IMPORTANT: Fixed length, each position has specific type
         variable "ingress_values" {
             type = tuple([number, string, number])
             description = "Network configuration (from_port,  ip_protocol, to_port )"
             default = [ 443, "tcp", 443 ]
         }
        ```
        

## any & null Types

1.  any
    
    Allows any type of value.
    
    ```
     variable "dynamic_value" {
       type = any
     }
    ```
    
2.  null
    
    Represents an intentionally unset value. Terraform uses null to evaluate defaults or ignore optional variables
    

## Conclusion

Today’s exploration of value-based type constraints adds another strong layer to Terraform fundamentals. Understanding how different data types work—primitive, complex, and flexible types—plays an important role in creating predictable, reusable, and well-structured infrastructure code.

Clear type definitions reduce errors, enforce consistency, and make large configurations far easier to maintain over time. As these concepts become more familiar through practice, Terraform setups naturally become more reliable and scalable.

## Reference

https://www.youtube.com/watch?v=gu2oCJ9DQiQ&list=PLl4APkPHzsUXcfBSJDExYR-a4fQiZGmMp&index=8
