locals {

  formatted_project_name_lower = lower(var.project_name)

  formatted_project_name = lower(replace(var.project_name, " ", "_"))

  # validations for the bucketname
  formatted_bucket_name = replace(
    replace(substr(lower(var.bucket_name), 0, 63), " ", "-"),
    "!",
    ""
  )

  port_list = split(",", var.allowed_ports)

  sg_rules = [for port in local.port_list : {
    name        = "port-${port}"
    port        = port
    description = "Allow traffic on port ${port}"
  }]

  instance_size = lookup(var.instance_sizes, var.environment, "t2.micro")

  # Get the current time when 'terraform apply' runs
  current_utc_time = timestamp()

  # Calculate 48 hours (2 days) from the base time
  expiry_48_hours = timeadd(local.current_utc_time, "48h")

  # Calculate a time 30 minutes in the past (using a negative duration)
  past_30_minutes = timeadd(local.current_utc_time, "-30m")

  # Format the timestamp to YYYYMMDD-hhmmss for a unique resource name
  formatted_name_suffix = formatdate("YYYYMMDD-hhmmss", local.current_utc_time)

  # Format the timestamp for a more human-readable tag
  formatted_tag = formatdate("DD MMM YYYY hh:mm ZZZ", local.current_utc_time)

  config_file_exists= fileexists("./config.json")

  user_data = local.config_file_exists ? jsondecode(file("./config.json"))  : null

  dir_name = dirname("./config.json") 
  base_name = basename("./config.json") 

  environment_settings = lookup(var.environment_settings["staging"], "instance_count", 1)

  supported_zone = element(var.supported_zones, 2)
  provisioned_zone = index(var.supported_zones, "us-east-1b")

  positive_cost = [for cost in var.monthly_cost : abs(cost)]
  max_cost = max(local.positive_cost...)
  min_cost = min(local.positive_cost...)

}
