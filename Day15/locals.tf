
locals {
  # --- Primary Instance User Data ---

  # Define the input file path
  primary_script_path = "setup-primary-instance.sh"

  # Use templatefile() to read the script and inject variables
  # It reads the file, substitutes the variables, and outputs the resulting string.
  primary_instance_user_data = templatefile(
    local.primary_script_path,
    {
      # These are the variables you want to pass into the script:
      primary_region = var.primary_region
    }
  )

  # --- Secondary Instance User Data ---

  #Define the input file path for the secondary scrip

  # Define the input file path
  secondary_script_path = "setup-secondary-instance.sh"
  # Use templatefile() to read the script and inject variables
  secondary_instance_user_data = templatefile(
    local.secondary_script_path,
    {
      # These are the variables you want to pass into the script:
      secondary_region = var.secondary_region
    }
  )


}
