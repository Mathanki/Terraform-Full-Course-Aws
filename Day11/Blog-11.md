
# Day 11: Terraform Functions | #30DaysOfAWSTerraform

Terraform provides a rich set of built-in functions that help transform, validate, and manipulate data within configuration files. These functions make Infrastructure as Code more flexible, dynamic, and reusable—especially when managing complex AWS deployments.

Today dives deep into the different categories of Terraform functions, explores how they work, and demonstrates where they fit in real-world scenarios.

## What Are Terraform Functions?

Terraform functions are built-in helpers that allow data processing inside configuration files. They eliminate the need for external scripts and enable more powerful, dynamic infrastructure definitions.

Functions are grouped into categories based on their purpose—**string manipulation**, **numeric operations**, **collection handling**, **validation**, **type conversion**, **date/time work**, **file processing**, and **data lookups**.

## Terraform Function Categories

In this blog, focus is on four key categories:

-   ### String Functions
    
    String functions help in formatting, transforming, and restructuring text values. These are commonly used for naming resources, generating IDs, cleaning input, and building dynamic strings.
    
    1.  **lower()**
        
        Converts any string to lowercase
        
        Example:
        
        ```
         lower("AWS-Prod")  #output "aws-prod"
        ```
        
    2.  **upper()**
        
        Converts a string to uppercase.
        
        Example:
        
        ```
         upper("my-bucket") #output "MY-BUCKET
        ```
        
    3.  **replace()**
        
        Replaces part of a string with a new value.
        
        Example:
        
        ```
         replace("demo bucket", " ", "-")  # Output: "demo-bucket"
        ```
        
    4.  **substr()**
        
        Extracts a substring starting at a specific index
        
        Example:
        
        ```
         substr("terraform", 0, 4)  # Output: "terr"
        ```
        
    5.  **trim()**
        
        Removes unwanted characters from the beginning and end of a string.
        
        Example:
        
        ```
         trim("  hello  ", " ") # Output: "hello"
        ```
        
    6.  **split()**
        
        Example:
        
        Splits a string into a list using a delimiter.
        
        ```
         split(",", "80,443,1200") # Output: ["80","443","1200"]
        ```
        
    7.  **join()**
        
        Joins a list of strings with a delimiter.
        
        Example:
        
        ```
         join("-", ["app", "backend", "01"]) # Output: "app-backend-01"
        ```
        
    8.  **chomp()**
        
        Removes trailing newline characters.
        
        Example:
        
        ```
         chomp("hello\n") #Output: "hello"
        ```
        

-   ### Numeric Functions
    
    Numeric functions help with math operations like rounding, selecting highest/lowest values, and calculating totals.
    
    1.  **abs()**
        
        Returns the absolute value (removes negative sign).
        
        Example:
        
        ```
         abs(-20) #Output : 20
        ```
        
    2.  **max()**
        
        Returns the largest number from a list.
        
        Example:
        
        ```
         max(5, 15, 25) #Output : 25
        ```
        
    3.  **min()**
        
        Returns the smallest value.
        
        Example:
        
        ```
         min(5, 15, 25)  #Output : 5
        ```
        
    4.  **ceil()**
        
        Rounds a number up to the nearest integer.
        
        Example:
        
        ```
         ceil(4.3)  #Output : 5
        ```
        
    5.  **floor()**
        
        Rounds a number down to the nearest whole number.
        
        Example:
        
        ```
         floor(4.9)  #Output : 4
        ```
        
    6.  **sum()**
        
        Adds all numbers inside a list.
        
        Example:
        
        ```
         sum([10, 20, 30]) #Output : 60
        ```
        

-   ### Collection Handling Functions
    
    These functions manipulate lists, sets, and maps — extremely useful when managing multiple resources or dynamic inputs.
    
    1\. **length()**
    
    Returns the number of items in a list, map, or set.
    
    Example:
    
    ```
      length(["a", "b", "c"]) #Output : 3
    ```
    
    2\. **concat()**
    
    Combines two or more lists.
    
    Example:
    
    ```
      concat(["a", "b"], ["c", "d"])  #Output :["a", "b", "c", "d"]
    ```
    
    3\. **merge()**
    
    Combines two or more lists.
    
    Example
    
    ```
      merge(
        { env = "dev" },
        { owner = "terraform" }
      )
       #Output : { env = "dev", owner = "terraform" }
    ```
    
    4\. **reverse()**
    
    Reverses the order of items in a list.
    
    Example
    
    ```
      reverse([1, 2, 3])
       #Output : [3, 2, 1]
    ```
    
-   ### Type Conversion Functions
    
    Terraform often requires converting values from one type to another—such as strings to numbers, lists to sets, or maps to lists—to ensure data is handled correctly. Type conversion functions help transform values into the format a resource, variable, or expression expects.
    
    1.  **toset()**
        
        Converts a list into a set (no duplicates, no order guaranteed).
        
        Example:
        
        ```
        toset(["a", "a", "b"])
        #Output :["a", "b"]
        ```
        
    2.  **tolist()**
        
        Converts tuples or sets into a list.
        
        Example:
        
        ```
        variable "my_set" {
        default = ["a", "b", "c"]
        }
        
        output "my_list" {
        value = tolist(var.my_set)
        }
        #Output : ["a", "b", "c"]
        ```
        
    3.  **tostring()**
        
        Converts any value into a string.
        
        Example:
        
        ```
        variable "instance_count" {
        default = 3
        }
        
        output "count_string" {
        value = tostring(var.instance_count)
        }
        #Output : "3"
        ```
        
    4.  **tonumber()**
        
        Converts any value into a string.
        
        Example:
        
        ```
        variable "port" {
        default = "8080"
        }
        
        output "port_number" {
        value = tonumber(var.port)
        }
        #Output : 8080
        ```
        
    5.  **tomap()**
        
        Converts an object or list of objects into a map.
        
        Example:
        
        ```
        variable "tags_object" {
        default = {
         Name = "App"
         Env  = "Dev"
        }
        }
        
        output "tags_map" {
        value = tomap(var.tags_object)
        }
        #Output: 
        tags_map = {
        "Env" = "Dev"
        "Name" = "App"
        }
        ```
        
    6.  **toobject()**
        
        Converts maps or structurally similar data into an object.
        
        Example:
        
        ```
        variable "config" {
        default = {
         memory = 1024
         cpu    = 2
        }
        }
        
        output "config_object" {
        value = toobject(var.config)
        }
        #Output:
        config_object = {
        "cpu" = 2
        "memory" = 1024
        }
        ```
        
    7.  **tuple()**
        
        Turns values into a tuple (ordered, may contain mixed types).
        
        Example:
        
        ```
        output "sample_tuple" {
        value = tuple("apple", 5, true)
        }
        
        #Output:
        sample_tuple = [
        "apple",
        5,
        true,
        ]
        ```
        
    8.  **list()**
        
        Creates a list with fixed items.
        
        Example:
        
        ```
        output "my_list" {
        value = list("one", "two", "three")
        }
        #Output:
        my_list = [
        "one",
        "two",
        "three",
        ]
        ```
        
        9.**set()**
        
        Creates a set with fixed values.
        
        Example:
        
        ```
        output "my_set" {
        value = set("a", "b", "c")
        }
        #Output:
        my_set = [
        "a",
        "b",
        "c",
        ]
        ```
        
        10.**map()**
        
        Creates a map explicitly.
        
        Example:
        
        ```
        output "my_map" {
        value = map("Name", "App", "Env", "Dev")
        }
        #Output:
        my_map = {
        "Env" = "Dev"
        "Name" = "App"
        }
        ```
        

## Real-World Example: Applying Terraform Functions in Action

Terraform functions become truly powerful when applied to everyday infrastructure tasks. Here are two practical examples that demonstrate how they streamline configuration and reduce repetitive code.

### Example 1: Creating Dynamic Security Group Rules from Input

Imagine a scenario where different environments require different inbound ports for an EC2 instance. Instead of manually writing multiple rules, Terraform functions can generate them dynamically.

Step 1 : Define a variable with comma-separated ports

```
variable "allowed_ports" {
  default = "22,80,443"
}
```

Step 2 : Convert the string into a list

```
port_list = split(",", var.allowed_ports)
```

Step 3: Use a for-expression to generate security group rules

```
 sg_rules = [for port in local.port_list : {
    name = "port-${port}"
    port = port
    description = "Allow traffic on port ${port}"
  }]
```

What’s happening here?

-   split() transforms a string → list
    
-   The for loop dynamically constructs a map for each port
    
-   This eliminates repetitive hard-coded rules and improves maintainability
    

### Example 2: Selecting Instance Size Based on Environment

Different environments (dev, staging, prod) often use different EC2 instance sizes. Instead of creating multiple conditionals, lookup() provides a clean and concise solution.

Define a map of instance sizes:

```
variable "instance_sizes" {
  default = {
    dev     = "t2.micro"
    staging = "t2.small"
    prod    = "t2.medium"
  }
}
```

Retrieve the instance size dynamically:

```
instance_size = lookup(var.instance_sizes, var.environment, "t2.micro")
```

How this works well:

-   lookup() retrieves the size based on the provided environment
    
-   A default value (t2.micro) ensures Terraform does not fail if the key is missing
    
-   This avoids long condition blocks and keeps the code flexible
    

## Conclusion

Terraform’s built-in functions play a crucial role in making configurations more dynamic, maintainable, and scalable. From manipulating strings to performing numeric calculations, handling complex collections, and converting data types, these functions simplify how infrastructure logic is expressed and reduce repetitive code.

A solid understanding of these functions empowers teams to build cleaner configurations, avoid common pitfalls, and create infrastructure that adapts intelligently to different environments and use cases. Leveraging these capabilities not only enhances efficiency but also promotes best practices in infrastructure as code.

Mastering these functions is a valuable step toward writing robust Terraform configurations that are easier to manage, extend, and automate.

## Reference
https://www.youtube.com/watch?v=-dKsmU4Z1hM&list=PLl4APkPHzsUXcfBSJDExYR-a4fQiZGmMp&index=16



