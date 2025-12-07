
# Day 13: Terraform Data Sources with AWS | #30DaysOfAWSTerraform

Terraform doesn’t just help create new cloud resources—it also integrates seamlessly with infrastructure that already exists. Day 13 explores one of Terraform’s most powerful capabilities: **data sources**, which allow configurations to reference AWS resources without managing them directly.

This is focuses on how data sources enable cleaner, more flexible Infrastructure as Code, especially when working with shared or pre-provisioned environments.

## What Are Terraform Data Sources?

Terraform **data sources** provide a way to **query AWS for information about existing resources**.

They are read-only, meaning Terraform can fetch values but cannot modify the resources they refer to.

Data sources are essential when:

-   Working in large environments where some resources already exist
    
-   Deploying into shared VPCs or networks
    
-   Avoiding hardcoding IDs such as VPC IDs, Subnet IDs, AMIs, etc.
    
-   Managing multi-team or multi-account infrastructure
    

## Why Use Data Sources?

Using Terraform data sources helps achieve:

-   Avoid Hardcoding : Instead of manually typing resource IDs, Terraform automatically retrieves them.
    
-   Better Automation: Code becomes more dynamic and environment-friendly.
    
-   Safe Integrations : Works seamlessly with pre-existing networks, IAM roles, security groups, and other AWS components.
    

Data sources in Terraform allow querying AWS for existing resources such as VPCs, subnets, AMIs, or security groups. Instead of recreating or hardcoding resource IDs, Terraform dynamically fetches the information at runtime.

This is especially useful in real-world environments where teams share networks, rely on common resources, or need to deploy into infrastructure created outside Terraform.

Now, let’s explore a few practical examples that demonstrate how Terraform data sources are used in real-world scenarios

## The Advantages of Using Data Sources

-   Reuse existing infrastructure : Reference VPCs, subnets, AMIs, IAM roles, etc., without managing them in the current state.
    
-   Reduce hardcoding: Dynamically fetch values (e.g., latest AMI by filters, VPC IDs) at plan time, making configs more portable and less brittle.
    
-   Fewer mistakes and less drift: Pull real values from the provider, reducing copy‑paste errors and stale configurations.
    
-   Team-friendly composition: One team provisions resources; other teams safely reference them via data sources to wire stacks together.
    

## Real-World Implementation Scenario : Launching EC2 Instances Dynamically Using Terraform Data Sources

In many organizations, network components such as VPCs, subnets, and AMIs are provisioned and maintained by separate teams. When deploying EC2 instances, manually tracking and entering these IDs becomes inefficient and error-prone. By leveraging Terraform data sources, these details can be fetched dynamically, allowing EC2 deployments to remain automated, accurate, and aligned with existing infrastructure.

For this demonstration, the VPC and subnet are pre-existing resources. The relevant details are outlined below.


### Step 1: Fetch Existing VPC

The first step is to configure a data source that queries AWS for the VPC information needed for our setup.

```
# Data source to get the existing VPC
data "aws_vpc" "shared-fetch-vpc" {
  filter {
    name   = "tag:Name"
    values = ["shared-network-vpc"]
  }
}
```

-   The Data keyword tells Terraform to **fetch** information from the cloud provider during the plan/apply stage, rather than creating or managing a resource.
    
-   Data sources are used to look up dynamic information, reference resources created by other teams, or retrieve resources from other Terraform configurations (if not using remote state).
    
-   "aws\_vpc": This is the **type** of data source, specifying that you are looking up an Amazon Web Services Virtual Private Cloud (VPC)
    
-   "shared-fetch-vpc": This is the **local name** you assign to this data block. You will use this name to reference the data source's attributes later in your configuration (e.g., [data.aws](http://data.aws/)\_[vpc.shared-fetch-vpc.id](http://vpc.shared-fetch-vpc.id/)).
    
-   The filter block is used to **specify the criteria** for finding the exact resource you want to retrieve. Since there could be many VPCs, the filter narrows down the results
    
-   name = "tag:Name": This instructs the AWS provider to look at the **tags** applied to the VPCs, specifically the one with the key Name.
    
-   values = \["shared-network-vpc"\]: This is the expected **value** of the Name tag. This block asks AWS: "Please find the ID of the VPC that has the tag Name set to the value shared-network-vpc.
    
    You can filter using the underlying properties of the VPC itself:
    
    1.  vpc-id: Filters the VPC using its unique ID (e.g., vpc-012345abcdef).
        
    2.  cidr-block: Filters the VPC based on its primary IPv4 CIDR block (e.g., 10.0.0.0/16)
        
    3.  is-default: Filters for the default VPC in the region (true or false).
        
    4.  owner-id: Filters the VPCs owned by a specific AWS account ID.
        
    5.  state: Filters based on the current state of the VPC (e.g., available or pending)
        
-   can include multiple filter blocks within the same data resource. Terraform treats these as a logical AND operation, meaning the VPC must satisfy all defined filters to be retrieved.
    
    Example:
    
    Find the VPC named shared-network-vpc AND whose CIDR block is 10.0.0.0/16.
    
    ```
      data "aws_vpc" "filtered_vpc" {
        filter {
          name   = "tag:Name"
          values = ["shared-network-vpc"]
        }
        filter {
          name   = "cidr-block"
          values = ["10.0.0.0/16"]
        }
      }
    ```
    

### Step 2 : Fetch Subnet

Next, configure a data source to retrieve the subnet associated with the selected VPC.

```
# Data source to get the existing subnet
data "aws_subnet" "shared-fetch-subnet" {
  filter {
    name   = "tag:Name"
    values = ["shared-primary-subnet"]
  }
  vpc_id = data.aws_vpc.shared-fetch-vpc.id  # ← Using first data source!
}
```

Its primary purpose is to **look up** an existing subnet in AWS and make its attributes (like its ID, CIDR block, etc.) available to the rest of your current Terraform configuration for use in resource creation.

-   data "aws\_subnet": This specifies that Terraform should fetch details about an AWS Subnet
    
-   This filter attempts to find subnets that have a tag key of Name with a value of shared-primary-subnet. This is a common method for identifying resources in AWS.
    
-   vpc\_id = [data.aws](http://data.aws/)\_[vpc.shared-fetch-vpc.id](http://vpc.shared-fetch-vpc.id/) It tells Terraform to limit its search to only those subnets that belong to the VPC whose ID was retrieved by the first data source ([data.aws](http://data.aws/)\_vpc.shared-fetch-vpc)
    
-   You can use the filter block with various name values to look up subnets based on their configuration attributes like subnet-id, cidr-block, availability-zone, availability-zone-id and state.
    

### Step 3 : Fetch Latest AMI

Rather than manually entering an AMI ID, define a data source to automatically retrieve the latest Amazon Linux 2 AMI

```
# Data source for the latest Amazon Linux 2 AMI
data "aws_ami" "amazon_server_ami_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
```

-   data "aws\_ami": This tells Terraform to look up an existing AMI in AWS.
    
-   "amazon\_server\_ami\_linux\_2": This is the local name you assign to this data source. You’ll use this name to reference the AMI elsewhere in your Terraform code.
    
-   most\_recent = true this ensures that Terraform retrieves the latest available AMI that matches the filters. Without this, Terraform might pick an older AMI that satisfies the filter conditions.
    
-   owners = \["amazon"\] this Filters AMIs to only those owned by Amazon. This ensures you get official Amazon Linux 2 AMIs, not community-created or third-party AMIs.
    
-   The first filter looks at the AMI’s name and uses a wildcard pattern to match names like amzn2-ami-hvm-\*-x86\_64-gp2. This ensures that only Amazon Linux 2 AMIs for the x86\_64 architecture with gp2 EBS storage are considered. The \* allows for any version number in the AMI name, so the filter can match the latest releases automatically.
    
-   The second filter checks the virtualization-type of the AMI and only allows HVM (Hardware Virtual Machine) AMIs. This ensures compatibility with modern EC2 instance types, avoiding older PV (Paravirtual) AMIs that may not work with newer instances.
    
-   Together, these filters guarantee that Terraform retrieves the latest official Amazon Linux 2 AMI that is HVM-based, x86\_64 architecture, and uses gp2 storage, providing a reliable and up-to-date base image for EC2 instances.
    

### Step 3 : Creating Compute Resources from Existing Infrastructure

Combine all the data sources and provision an EC2 instance dynamically. This is a best practice for writing reusable, environment-agnostic Terraform code.

```
resource "aws_instance" "server1" {
    ami = data.aws_ami.amazon_server_ami_linux_2.id
    instance_type = "t2.micro"
    subnet_id = data.aws_subnet.shared-fetch-subnet.id
    tags = {
        Environment = "dev"
    }
}
```

-   ami = [data.aws](http://data.aws/)\_[ami.amazon](http://ami.amazon/)\_server\_ami\_linux\_[2.id](http://2.id/) This instance will automatically use the specific AMI that was looked up and retrieved by that data source
    
-   subnet\_id automatically placed into the existing subnet that was successfully located and fetched by the data source
    

aws\_instance.server1 block is an example of modular and decoupled infrastructure code. It creates a basic EC2 server, but relies completely on pre-existing network infrastructure (VPC and Subnet) and a dynamically sourced AMI to define its configuration. This pattern eliminates hardcoded IDs and makes the configuration adaptable to different environments.

![](day-13-terraform/ff0a2ff8-68cf-461f-99aa-24ceecb57657.png)

## Data Source Behavior and Refresh

Data Sources operate dynamically throughout the Terraform workflow.

When Data Sources are Queried, Terraform attempts to query Data Sources during the planning phase to ensure the fetched data is available for use in resource planning. However, the read operation may be deferred to the apply phase if any of the Data Source's arguments rely on a value that is not yet known (i.e., it depends on a resource being created in the current plan).

Data Sources are always read from the provider (e.g., calling the AWS API) during the planning process. They are not read from the Terraform state file (unlike managed resources). This ensures that the data your configuration depends on is always up to date before creating or modifying any resources.

## Handling No Matches (Common Failure)

1.  **Failure on Zero Results**
    
    The most frequent error with Data Sources occurs when the query fails to find the exact resource defined by the filters. By default, if a Data Source query returns zero results (meaning no existing resource matches all the filters provided in the block), Terraform considers this a fatal error and will fail the plan or apply operation.
    
    Example:
    
    Error: no matching VPC found
    
    Reasoning**:** Terraform treats the existence of the object you are searching for as an assertion. If the object doesn't exist, the configuration cannot be applied correctly.
    
2.  **Failure on Multiple Matches**
    
    The standard Data Source block (like data "aws\_subnet" "example") is designed to return a single, unique result. If filters are too broad and the query returns multiple matching resources (e.g., two subnets with the exact same non-unique tag), the Data Source will also typically throw an error, as it cannot determine which single resource to return.
    
    The Fix:
    
    Always use filters that lead to a unique match, such as combining filters (like filtering by both tag:Name and vpc\_id).
    
    Retrieving lists of resources, which can then be used with functions like tolist or element.
    

## Conclusion

Terraform data sources play a crucial role in building adaptable cloud environments. They allow configurations to interact with existing AWS resources effortlessly, unlocking more flexible and maintainable Infrastructure as Code. Whether deploying into shared networks or integrating with legacy environments, data sources provide the visibility and consistency needed for modern cloud automation.

## Reference

https://www.youtube.com/watch?v=MSr67lWCyD8&list=PLl4APkPHzsUXcfBSJDExYR-a4fQiZGmMp&index=15
