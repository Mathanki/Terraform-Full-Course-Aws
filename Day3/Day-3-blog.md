# Day 3: Creating a VPC and S3 Bucket with Terraform — #30DaysOfAWSTerraform
Today, the concept of **Infrastructure-as-Code (IaC)** truly clicked as I transitioned from Terraform theory to provisioning tangible AWS resources. After laying the foundation with provider setup and versioning best practices, the focus shifted to building blocks that matter: an **AWS VPC** and an **S3 Bucket** and learned how Terraform automatically handles implicit dependencies between resources.

### Prerequisites and Initial Configuration

Before Terraform can provision a single resource (like an S3 bucket or a VPC), it needs permission to talk to the AWS API. This is handled through **Authentication**. There are several ways to provide your credentials, but the most common and recommended methods for a local setup are:

1.  AWS CLI Configuration (Recommended for Local Dev)

This is the most straightforward method. You use the AWS Command Line Interface to store your credentials in a standard location on your computer.

Press enter or click to view image in full size

![](day-3-creating/260ed624-80e5-49e4-b701-c77595e36e62.png)

2\. Environment Variables (Good for CI/CD)

For deployment pipelines or quick scripts, setting environment variables is fast and effective.

Using **Command Prompt** use the `set` command. This variable will only be set for the current Command Prompt session.

![](day-3-creating/0992a3ed-9692-4d55-bd57-162524669e76.png)

Once this was done, Terraform was ready to deploy resources into my AWS account.

### Infrastructure Setup: VPC and S3

My goal was to implement a straightforward AWS setup using **Terraform**. This exercise was specifically designed to illustrate how Terraform automatically manages resource relationships (implicit dependencies).

**Core Components:**

-   An AWS Virtual Private Cloud (**VPC**)
-   An S3 bucket for data storage

**Key Requirement (Dependency):**

-   The S3 bucket name must dynamically include the ID of the newly created VPC.

This project provided valuable insight into how Terraform infers and manages resource dependencies based on attribute references, eliminating the need for explicit `depends_on` statements in this scenario.

Here is the complete code I implemented:

```
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}


provider "aws" {
  region = "us-east-1"
}


resource "aws_vpc" "demo_vpc"{
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "My_demo_vpc"
  }
}


resource "aws_s3_bucket" "first_demo_bucket"{
  bucket = "tech-demo-mathanki-bucket-1-${aws_vpc.demo_vpc.id}"

  tags = {
    Name        = "My bucket 1.0"
    Environment = "Dev"
  }
}

```

Execution Flow:

1.  terraform init:

Before running any commands, we initialize the configuration.

-   Downloaded the AWS provider (version 5.x as defined in the configuration).
-   Set up the working directory and installed necessary modules.


2\. terraform plan:

Terraform generated an execution plan, showing exactly what would be created or modified. 1VPC, 1 S3 Bucket

Press enter or click to view image in full size

![](day-3-creating/67211371-6812-4f0f-8183-798f1446bf38.png)

3\. terraform apply:

After confirming the plan, Terraform executed the changes:

. Created VPC

. Fetched its ID — Acquired the unique identifier of the newly created VPC

. Used that ID to create the S3 bucket with a unique name

Press enter or click to view image in full size

![](day-3-creating/6ed88a38-1b43-4d8f-a572-99bcdbeb9e22.png)

Press enter or click to view image in full size

![](day-3-creating/4da47415-aea5-4cfb-9200-b18900d9fa04.png)

Press enter or click to view image in full size

![](day-3-creating/551c960d-38a6-4d29-9408-d2005e65f7c2.png)

4\. terraform destory:

Terraform command used to **delete all resources** previously created by Terraform in the current workspace.

Press enter or click to view image in full size

![](day-3-creating/78671a7a-bcae-45dc-96f9-3c3bdd52cd81.png)

### Terraform’s Implicit Dependencies

Terraform analyzes the code and automatically determines which resources depend on others based on **references**.

In my code:

```
 bucket = "tech-demo-mathanki-bucket-1-${aws_vpc.demo_vpc.id}"
```

The S3 bucket **depends on** the VPC because it references a property from the VPC resource

1.  Terraform must first create the VPC
2.  Then generate the bucket name
3.  Then create the S3 bucket

### Conclusion

oday’s work wasn’t merely about writing a few lines of code to deploy a simple application or service — many people can manage that using quick console commands.

What I learned was much more powerful:

-   Terraform can automatically determine dependencies between resources.
-   Implicit dependencies occur when one resource references another.
-   How to manage code clean, readable, and declarative.
-   Infrastructure ordering becomes fully automated.

This foundational understanding is the true value gained, equipping me to build, manage, and scale complex cloud environments efficiently.

### Reference:

[Create an AWS S3 Bucket Using Terraform](https://www.youtube.com/watch?v=09HQ_R1P7Lw&list=PLl4APkPHzsUXcfBSJDExYR-a4fQiZGmMp&index=4)
