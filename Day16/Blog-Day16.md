
# Day 16: AWS IAM User Management with Terraform | #30DaysOfAWSTerraform

Cloud security begins with a fundamental principle: controlling exactly who can perform specific actions within your environment. For teams operating on Amazon Web Services (AWS), this concept of **Identity and Access Control** is the absolute bedrock of their security posture. However, trying to manage this crucial access manually by interacting directly with the AWS console is highly problematic. This approach quickly becomes error-prone, leads to inconsistent security configurations across your different teams and projects, and makes the essential process of checking and verifying permissions (known as auditing) exceedingly difficult.

Today’s focus is on a practical and widely used IAM automation workflow: creating multiple AWS IAM users from a CSV file and automatically organizing them into the right IAM groups based on attributes such as **department** and **job title**. This approach eliminates manual user creation, reduces errors, and ensures that teams receive correct permissions from day one.

The workflow covers more than just user creation. It also includes:

-   **Assigning IAM policies to each group**, so permissions are managed at the group level instead of individually.
    
-   **Enabling MFA (Multi-Factor Authentication) for all newly created users** to strengthen account security and enforce best practices across the organization
    
-   **Generating console login credentials** so users can immediately access the AWS Management Console with secure, role-appropriate access.
    

By combining CSV-based automation, group-level permission assignment, and mandatory MFA, this solution helps maintain a scalable, secure, and well-organized IAM structure—ideal for growing teams or enterprise environments.

![](day-16-aws/40f71a47-977d-4451-8a7d-99c6fcb3c76e.png)

Bulk-create **26 IAM users** using a `users.csv` file and automate the entire user-provisioning workflow.

**Key Features:**

1.  Dynamic Group Assignment
    
    Users are automatically mapped to IAM groups such as **education**, **engineers**, and **managers** based on attributes defined in the CSV file.
    
2.  Console Access with Temporary Passwords
    
    Each IAM user is created with console login enabled, using a mandatory **temporary password** that requires reset at first sign-in.
    
3.  Secure State Management with S3 Backend
    
    All Terraform state files are stored remotely using an **S3 backend**, ensuring safe, consistent, and collaborative state handling.
    
4.  Standardized Username Format
    
    Usernames follow a clear naming convention:
    
    **first initial + last name**
    
    Example:
    
    Michael Scott → **mscott**
    
5.  Group Policies Automatically Applied
    
    Every group receives predefined IAM policies that match its responsibilities.
    
    For example:
    
    -   **education group:** read-only access to training resources
        
    -   **engineers group:** EC2, S3, VPC, or development-related permissions
        
    -   **managers group:** broader visibility across accounts or billing insights
        

Attaching policies at the **group level** ensures consistent permissions and easier long-term maintenance.

6.  Enforcing MFA for All Users
    
    To strengthen security, every user is required to set up **Multi-Factor Authentication (MFA)** after their first login.
    
    Terraform assigns an IAM policy that **denies all actions unless MFA is enabled**, ensuring the highest level of account protection.
    
    Example behavior:
    
    -   User logs in → can’t access anything
        
    -   Until they configure MFA
        
    -   After MFA setup → full access based on their group policies
        

## Core Implementation: Automating IAM User Creation from CSV

The workflow begins with a **CSV file** that stores employee information such as first name, last name, department, and job title. Terraform’s `csvdecode()` function converts this raw file into structured data that can be used directly within our configuration.

```
locals {
 # Read the contents of the users.csv file
  users_csv_content = file("users.csv")

  # Decode the CSV content into a list of objects (dictionaries)
  # The 'users' local variable will be a list of user objects.
  users_data = csvdecode(local.users_csv_content)
}
```

Once the CSV is decoded, Terraform’s iteration features take over. Using `for_each`, we dynamically provision IAM users based on the records in the CSV:

```
// aws iam user 
resource "aws_iam_user" "users" {
  for_each = { for user in local.users_data : user.first_name => user }
  // offset and length value 
  name = lower("${substr(each.value.first_name, 0, 1)}${each.value.last_name}")
  path = "/users/"

  tags = {
    Name       = "${each.value.first_name} ${each.value.last_name}"
    Department = each.value.department
    JobTitle   = each.value.job_title

  }
}
```

This logic automatically produces clean, standardized usernames—such as **jsmith** for _John Smith_—ensuring consistency across the entire set of 26 users without any manual input. Each user entry in the CSV directly translates into an IAM identity, making the onboarding process efficient, scalable, and error-free.

## Dynamic Group Assignment Using Conditional Logic

Manually placing users into IAM groups can be error-prone, especially in environments where teams grow, roles shift, and responsibilities evolve. To solve this, the Terraform configuration applies **conditional, attribute-based logic** to determine exactly which group a user belongs to.

For example, users can be automatically grouped by department:

```
# Add users to the Engineers group
resource "aws_iam_group_membership" "engineers_members" {
  name  = "engineers-group-membership"
  group = aws_iam_group.engineers.name

  users = [
    for user in aws_iam_user.users : user.name if user.tags.Department == "Engineering" # Note: No users match this in the current CSV
  ]
}
```

This ensures that anyone tagged as part of the **Engineering** department is instantly added to the engineering group—no manual intervention required.

```
resource "aws_iam_group_membership" "education_members" {
  name  = "education-group-membership"
  group = aws_iam_group.education.name

  users = [
    for user in aws_iam_user.users : user.name if user.tags.Department == "Education"
  ]
}

# Add users to the Managers group
resource "aws_iam_group_membership" "managers_members" {
  name  = "managers-group-membership"
  group = aws_iam_group.managers.name

  users = [
    for user in aws_iam_user.users : user.name if contains(keys(user.tags), "JobTitle") && can(regex("Manager|CEO", user.tags.JobTitle))
  ]
}
```

For more advanced scenarios, group membership can be determined using multiple conditions, such as job title, seniority, or other metadata.

This approach allows Terraform to automatically identify managers and directors, placing them in leadership-specific IAM groups. As soon as a user’s attributes change in the CSV, Terraform seamlessly updates their group membership on the next run.

The result is a dynamic, scalable access-control model that continuously aligns with the organization’s structure—ensuring the right users always receive the right permissions.

## Role-Based Access: Attaching Policies to IAM Groups

Once users are automatically assigned to their respective groups, the next step is ensuring each group receives the correct level of access. Instead of attaching permissions directly to individual users, the configuration applies **AWS managed policies** at the group level—a best practice that keeps permissions consistent, scalable, and easy to maintain.

Each group (Education, Managers, and Engineers) has its own curated list of IAM policies stored in locals. Terraform then loops through these lists and attaches every required policy to the correct group

Education Group Policies:

```
resource "aws_iam_group_policy_attachment" "education_group_policy" {
  for_each   = toset(local.education_policies)
  group      = aws_iam_group.education.name
  policy_arn = each.value
}
```

The **education group** might include read-only or limited-access policies—ideal for training teams or support roles. Terraform creates a policy attachment for each ARN defined in [`local.education`](http://local.education/)`_policies`.

Manager Group Policies:

```
resource "aws_iam_group_policy_attachment" "manager_group_policy" {
  for_each   = toset(local.managers_policies)
  group      = aws_iam_group.managers.name
  policy_arn = each.value
}
```

Members of the **managers group** typically require broader visibility—such as billing, usage insights, or resource dashboards. Using a loop ensures every necessary policy is consistently applied.

Engineers Group Policies:

```
resource "aws_iam_group_policy_attachment" "engineers_group_policy" {
  for_each   = toset(local.engineers_policies)
  group      = aws_iam_group.engineers.name
  policy_arn = each.value
}
```

The **engineers group** generally receives more technical permissions (EC2, S3, CloudWatch, Lambda, etc.). Terraform automatically attaches all engineering-related policies included in `local.engineers_policies`.

## Security by Default: Temporary Credentials and Mandatory MFA

Security is built into the workflow from the very beginning. As soon as IAM users are created, Terraform enforces strict authentication practices to protect access to the AWS environment.

**Mandatory Password Reset on First Login**

Each user is assigned a temporary console password that must be changed immediately upon first login. This ensures no default or reused credentials stay active.

```
resource "aws_iam_user_login_profile" "users" {
  for_each                = aws_iam_user.users
  password_reset_required = true
}
```

This guarantees secure onboarding without manual administration.

**Virtual MFA Device Provisioning**

Terraform also prepares each user for Multi-Factor Authentication by creating a virtual MFA device resource:

```
resource "aws_iam_virtual_mfa_device" "users" {
  for_each                 = aws_iam_user.users
  virtual_mfa_device_name  = each.value.name
}
```

While Terraform can create the device, users still must scan the QR code and activate MFA themselves—ensuring the human-in-the-loop step necessary for secure enrollment.

**Enforcing MFA With IAM Policy**

To ensure MFA is not optional, a custom IAM policy is applied that restricts actions unless MFA is enabled. If the user logs in without MFA, permissions are automatically denied.

```
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowAllAuthenticated",
      "Effect": "Allow",
      "Action": "*",
      "Resource": "*"
    },
    {
      "Sid": "DenyAccessUnlessMFA",
      "Effect": "Deny",
      "NotAction": [
        /* ... Exceptions for MFA management ... */
      ],
      "Resource": "*",
      "Condition": {
        "BoolIfExists": {
          "aws:MultiFactorAuthPresent": "false"
        }
      }
    }
  ]
}
```

We transform this JSON policy into a managed AWS resource and apply it at scale to all relevant security principals (IAM Groups).

The central statement in the policy is the explicit **DENY** rule (`"Effect": "Deny"`). This rule is applied only if the following condition is met: **Condition:** `"aws:MultiFactorAuthPresent": "false"`

If a user signs in with only their username and password, the AWS session variable `aws:MultiFactorAuthPresent` is set to `"false"`. This immediately activates the Deny rule, blocking access to almost everything.

The JSON policy is defined as an `aws_iam_policy` resource. This single policy is then attached to multiple relevant user groups (e.g., `education`, `managers`, `engineers`) using the `aws_iam_group_policy_attachment` resource

```
# Create the IAM Policy resource from the JSON file
resource "aws_iam_policy" "mfa_enforcement" {
  name        = "MFAEnforcementPolicy-DepartmentUsers"
  description = "Forces users to use MFA for all actions except enabling MFA"
  # Loads the content of the mfa_enforcement_policy.json file
  policy      = file("mfa_enforcement_policy.json")
}

# Attach the MFA Enforcement Policy to all department groups
resource "aws_iam_group_policy_attachment" "mfa_policy_attachment_education" {
  group      = aws_iam_group.education.name
  policy_arn = aws_iam_policy.mfa_enforcement.arn
}

# Attach the MFA Enforcement Policy to all managers groups
resource "aws_iam_group_policy_attachment" "mfa_policy_attachment_managers" {
  group      = aws_iam_group.managers.name
  policy_arn = aws_iam_policy.mfa_enforcement.arn
}


# Attach the MFA Enforcement Policy to all engineers groups
resource "aws_iam_group_policy_attachment" "mfa_policy_attachment_engineers" {
  group      = aws_iam_group.engineers.name
  policy_arn = aws_iam_policy.mfa_enforcement.arn
}
```

This **deny-until-MFA-enabled** strategy ensures that users cannot access sensitive AWS resources until they complete MFA setup, giving your environment an additional layer of protection by default.

Every user in the attached groups is instantly subject to the MFA enforcement rule. If a user logs in without providing an MFA code:

1.  They attempt to access an AWS service (e.g., EC2).
    
2.  The **Deny** rule (triggered by `"aws:MultiFactorAuthPresent": "false"`) overrides any group-level **Allow** permissions.
    
3.  The request is denied, and they are forced to enable and use MFA to regain full access.
    

## **Conclusion**

Implementing AWS IAM through Terraform turns user and access management into a predictable, automated, and highly scalable process. This approach showcases how modern organizations can strengthen security while reducing operational overhead.

With Terraform driving the workflow, IAM user creation becomes repeatable and error-free—whether managing 10 users or thousands. Group policies, MFA enforcement, and temporary credential workflows ensure that security standards are consistently applied across the board. Tag-based logic makes the system adaptive, automatically aligning user access with their roles and responsibilities as organizational needs evolve.

Beyond initial provisioning, the ongoing benefits are even more impactful. A simple update to the CSV can realign group memberships instantly. Policy changes propagate uniformly without manual intervention. Every configuration is stored in version control, supporting audits, compliance, and collaborative operations.

By embracing IAM as Infrastructure as Code, teams gain a secure, flexible, and future-ready identity management foundation—one that grows seamlessly with the organization and supports stronger cloud governance in every stage of maturity

## Reference

https://www.youtube.com/watch?v=33dWo4esH1U&list=PLl4APkPHzsUXcfBSJDExYR-a4fQiZGmMp&index=18