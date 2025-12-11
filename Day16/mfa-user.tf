# Create virtual MFA devices for each user
# Note: The actual MFA setup requires user interaction (scanning QR code)
# This creates the MFA device resource that users will configure

resource "aws_iam_virtual_mfa_device" "users" {
  for_each = aws_iam_user.users

  virtual_mfa_device_name = each.value.name
  path                    = "/mfa/"

  tags = {
    "User"       = each.value.name
    "ManagedBy"  = "Terraform"
    "Purpose"    = "User MFA Authentication"
  }
}

# Set a strong account password policy
resource "aws_iam_account_password_policy" "strict" {
  minimum_password_length        = 14
  require_lowercase_characters   = true
  require_uppercase_characters   = true
  require_numbers                = true
  require_symbols                = true
  allow_users_to_change_password = true
  max_password_age               = 90    # Password expires after 90 days
  password_reuse_prevention      = 5     # Cannot reuse last 5 passwords
  hard_expiry                    = false # User can change password after expiry
}