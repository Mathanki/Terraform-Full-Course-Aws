
# Day 12: Terraform Functions | (Part 2) — File, Time, Validation & Lookup Essentials #30DaysOfAWSTerraform

Terraform provides a wide range of built-in functions that make infrastructure code dynamic, predictable, and highly reusable. In this part of the series, the focus is on four important categories of functions that support everyday automation: **File functions**, **Date/Time functions**, **Validation functions**, and **Lookup functions.**

These functions play a powerful role in improving workflows, reading external configuration, validating inputs, generating timestamps, and safely retrieving values from complex data structures.

## Validation Functions

-   Validation functions help ensure configurations follow patterns, constraints, and correct data formats preventing errors before they occur. This often used within input variable blocks (variable) using the validation argument to enforce constraints on the values provided by users.
    
    1.  **regex()**
        
        Extracts substrings that match a regular expression.
        
        Example: Ensuring an AWS Region variable follows the expected format
        
        In this example, we use the regex check to throw an error if the input string **does not** match the pattern of two lowercase letters, a hyphen, lowercase letters, a hyphen, and number (e.g us-east-1 or eu-west-2).
        
        ```
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
        ```
        
        If the input is invalid (no match is found), the regex() function will fail, but can() will catch that failure and return false.
        
        ![](day-12-terraform/af83ee20-bd63-49d7-9caa-e92e3be0c6c4.png)
        
    2.  **can()**
        
        The can() function takes an expression and returns true if the expression evaluates successfully without producing an error, and false if it produces an error. It's excellent for testing if a type conversion or a function like regex() will succeed.
        
        Example: Ensuring a CIDR block is valid
        
        cidrhost() as the expression inside can(). If the input var.ip\_range is not a syntactically valid CIDR range (e.g., 10.0.0.0/16), cidrhost() will error, and can() will return false, triggering the validation error.
        
        ![](day-12-terraform/2b331fa4-2705-41dc-bb16-2ac621245424.png)
        
    3.  **contains()**
        
        The contains() function tests if a list or set contains a specific value, or if a map contains a specific key. It returns true if the value is present.
        
        Example: Limiting Instance Types to approved values
        
        This ensures that the user selects one of the approved small, cost-effective instance types.
        
        ```
         variable "instance_type" {
           description = "The EC2 instance type to use."
           type        = string
           default = "t2.micro"
           validation {
             # Checks if the input is one of the allowed types.
             condition     = contains(["t2.micro", "t3.small", "t3a.small"], var.instance_type)
             error_message = "The instance_type must be t2.micro, t3.small, or t3a.small."
           }
         }
        ```
        
        ![](day-12-terraform/1ea313c4-b8b3-4327-b7b2-f03266fde29e.png)
        
    4.  **startswith() / endswith()**
        
        These functions test if a given string begins or ends with a specified prefix or suffix string, respectively.
        
        Example: Enforcing Naming Conventions
        
        This ensures that a bucket name starts with a specific project code and ends with a specific environment tag.
        
        ```
         variable "bucket_resource_name" {
           description = "A name for the resource."
           type        = string
           default = "proj-A-bucket1-prod"
           validation {
             # Ensure the name starts with "proj-A-" AND ends with "-prod"
             condition     = startswith(var.bucket_resource_name, "proj-A-") && endswith(var.bucket_resource_name, "-prod")
             error_message = "Bucket name must start with 'proj-A-' and end with '-prod' (e.g., proj-A-webserver-prod)."
           }
         }
        ```
        
        ![](day-12-terraform/9355b6c7-af18-4bd2-bdb9-edcc1458562e.png)
        
-   ## Date & Time Functions
    
    Terraform includes built-in time functions for timestamping deployments, generating unique IDs, and scheduling time-based resources.
    
    1.  **timestamp()**
        
        This function returns the current time in UTC, formatted according to RFC 3339 (e.g., YYYY-MM-DDThh:mm:ssZ). The exact timestamp is determined at the moment the `terraform apply` command runs.
        
        ```
         locals {
           # Get the current time when 'terraform apply' runs
           current_utc_time = timestamp() 
         }
        
         output "current_time_output" {
           value = local.current_utc_time
           # Example output: "2025-12-05T18:49:46Z"
         }
        ```
        
    2.  **timeadd()**
        
        This function calculates a new timestamp by adding a specified duration to a given timestamp. It returns the result as an RFC 3339 formatted string.
        
        ```
         locals {
           # Get the current time
           base_time = timestamp() 
        
           # Calculate 48 hours (2 days) from the base time
           expiry_48_hours = timeadd(local.base_time, "48h") 
        
           # Calculate a time 30 minutes in the past (using a negative duration)
           past_30_minutes = timeadd(local.base_time, "-30m") 
         }
        
         output "expiry_time_output" {
           value = local.expiry_48_hours
           # Example output: "2025-12-07T18:49:46Z" (48 hours later)
         }
        ```
        
    3.  **formatdate()**
        
        This function converts an RFC 3339 timestamp string into a custom format defined by a format specification string.
        
        ```
         locals {
           # Get the current time
           current_time = timestamp() 
        
           # Format the timestamp to YYYYMMDD-hhmmss for a unique resource name
           formatted_name_suffix = formatdate("YYYYMMDD-hhmmss", local.current_time) 
        
           # Format the timestamp for a more human-readable tag
           formatted_tag = formatdate("DD MMM YYYY hh:mm ZZZ", local.current_time)
         }
        
         output "formatted_name_suffix" {
           value = local.formatted_name_suffix
           # Example output: "20251205-184946"
         }
        
         output "formatted_tag_output" {
           value = local.formatted_tag
           # Example output: "05 Dec 2025 18:49 UTC"
         }
        ```
        

-   ## File Functions
    
    File functions allow Terraform to read, inspect, and interact with files on the local filesystem. These are especially useful when working with scripts, policies, configuration files, and template-based deployments.
    
    1.  **file()**
        
        The file() function reads the contents of a file at a given path and returns it as a string
        
        Example:
        
        ```
         locals {
           user_data = file("./config.json")
         }
         output "file_content" {
           value = local.user_data
         }
        ```
        
        ![](day-12-terraform/742caf98-4f11-4439-964c-f5d7215e8f71.png)
        
    2.  **fileexists()**
        
        The fileexists() function checks whether a file exists at a given path. It returns true if the file exists and is a regular file, and false otherwise.
        
        Example:
        
        ```
         config_file_exists= fileexists("./config.json")
        
         user_data = local.config_file_exists ? jsondecode(file("./config.json"))  : null
        ```
        
        if the config file exits fileexists function return true then it read the content and return
        
    3.  **dirname()**
        
        Extracts only the directory part of a file path.
        
        Example:
        
        ```
         dirname("/root/app/config.json") 
         #Output: "/root/app"
        ```
        
    4.  **basename()**
        
        Extracts only the file name from a path.
        
        Example:
        
        ```
         basename("/root/app/config.json") 
         #Output:  "config.json"
        ```
        

## Lookup Functions

-   Lookup functions make it easy to retrieve values from lists and maps safely especially useful for multi-environment workflows.
    
    1.  lookup()
        
        The lookup() function is typically used to retrieve a value from a map (or dictionary/object) based on a provided key. It often includes an optional default value to return if the key is not found, making the retrieval "safe.
        
        ```
         variable "environment_settings" {
           default = {
             "prod" : {"region" : "us-east-1", "instance_count" : 5  },
             "staging" : {"region" : "us-west-2", "instance_count" : 3 },
             "dev" : {"region" : "eu-central-1", "instance_count" : 1 }
           }
         }
        
         locals{
         environment_settings = lookup(var.environment_settings["staging"], "instance_count", 1)
         }
        ```
        
        it reurn the instance\_ount as 3, when instance\_count doesn't exist in the map then it return the default value as 1that is passed as last parameter
        
    2.  element()
        
        The element() function is generally used to retrieve a single item from a list (or array) based on its numerical index. It is often used to ensure the index is valid.
        
        Example: Get the third supported availability zone from the list.
        
        ```
         variable supported_zones {
           default= ["us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d"]
         } 
        
         locals{
         supported_zone = element(var.supported_zones, 2)
         }
        ```
        
    3.  index()
        
        The index() function is commonly used to find the numerical position (index) of a specific value within a list.
        
        Example: Find out the index of the availability zone "us-east-1b" in the list of currently supported zones .
        
        ```
         variable supported_zones {
           default= ["us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d"]
         } 
         locals{
           provisioned_zone_index = index(var.supported_zones, "us-east-1b")
         }
        ```
        

it return the index as 1

## Sensitive Variable

The purpose of marking variables and outputs as sensitive is to protect confidential information from being displayed in various output locations, enhancing security.

sensitive = true: This argument tells Terraform to mask the value of this variable in the CLI output when running commands like terraform plan or terraform apply.

```
variable "credentials" {
  default = "xyz123"
  sensitive = true
}
output "credentials"{
    value = var.credentials
}
```

Terraform will show mask output instead of the actual string xyz123 in the logs and standard terminal output.

## Conclusion

File, Date/Time, Validation, and Lookup functions play a crucial role in making Terraform configurations more dynamic, reliable, and production-ready. These functions allow Terraform to interact with external files, generate consistent timestamps, enforce input correctness, and safely retrieve values from lists and maps. By incorporating these capabilities into infrastructure-as-code workflows, configurations become cleaner, more adaptable, and significantly easier to maintain. Understanding and using these functions effectively strengthens the overall structure of any Terraform project and sets a strong foundation for more advanced automation.

## Reference
https://www.youtube.com/watch?v=ZYCCu9rZkU8&list=PLl4APkPHzsUXcfBSJDExYR-a4fQiZGmMp&index=13
