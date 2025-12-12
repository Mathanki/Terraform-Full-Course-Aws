data "aws_elastic_beanstalk_solution_stack" "latest_nodejs20_al2023" {
  most_recent = true
  # Regex pattern to match the latest AL2023 and Node.js 20 version
  name_regex  = "^64bit Amazon Linux 2023 v.* Node\\.js 20$"
}