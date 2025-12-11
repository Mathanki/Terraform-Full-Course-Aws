output "users_names" {
  // get the user name 
  value = [for user in local.users_data : "${user.first_name} ${user.last_name}"]
}

// user password
output "user_passwords" {
  value = {
    for user, profile in aws_iam_user_login_profile.users_profile :
    user => "Password created - user must reset on first login"
  }
  sensitive = true
}

output "mfa_device_arns" {
  description = "ARNs of the virtual MFA devices created for users"
  value = {
    for user, mfa in aws_iam_virtual_mfa_device.users :
    user => mfa.arn
  }
}

output "mfa_setup_instructions" {
  description = "Instructions for users to setup MFA"
  value       = "Users must configure their MFA devices by: 1) Login to AWS Console 2) Go to IAM > Security Credentials 3) Assign MFA device 4) Scan QR code with authenticator app"
}