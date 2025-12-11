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


