#Attach appropriate AWS managed policies to each group based on their role

# attach policy for eduction group
resource "aws_iam_group_policy_attachment" "education_group_policy" {
  # Creates one resource instance for each ARN in the set
  for_each = toset(local.education_policies)
  group    = aws_iam_group.education.name
  # The value of each element (the ARN) is used for policy_arn
  policy_arn = each.value
}

# attach policy for manager group
resource "aws_iam_group_policy_attachment" "manager_group_policy" {
  # Creates one resource instance for each ARN in the set
  for_each = toset(local.managers_policies)
  group    = aws_iam_group.managers.name
  # The value of each element (the ARN) is used for policy_arn
  policy_arn = each.value
}


# attach policy for engineers group
resource "aws_iam_group_policy_attachment" "engineers_group_policy" {
  # Creates one resource instance for each ARN in the set
  for_each = toset(local.engineers_policies)
  group    = aws_iam_group.engineers.name
  # The value of each element (the ARN) is used for policy_arn
  policy_arn = each.value
}

