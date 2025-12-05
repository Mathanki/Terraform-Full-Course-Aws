output "formatter_project_name" {
  value = local.formatted_project_name
}

output "formated_bucket_name"{
    value = local.formatted_bucket_name
}

output "list_of_ports"{
    value = local.port_list
}

output "sg_rules"{
    value = local.sg_rules
}

output "selected_instance_size"{
    value = local.instance_size
}

output "current_time_output" {
  value = local.current_utc_time
  # Example output: "2025-12-05T18:49:46Z"
}

output "expiry_time_output" {
  value = local.expiry_48_hours
  # Example output: "2025-12-07T18:49:46Z" (48 hours later)
}

output "formatted_name_suffix" {
  value = local.formatted_name_suffix
  # Example output: "20251205-184946"
}

output "formatted_tag_output" {
  value = local.formatted_tag
  # Example output: "05 Dec 2025 18:49 UTC"
}

output "file_content" {
  value = local.user_data
}
output "dir_name" {
  value = local.dir_name
}

output "base_name" {
  value = local.base_name
}

output "environment_settings" {
  value = local.environment_settings
}

output "supported_zone"{
    value = local.supported_zone
}

output "provisioned_zone_index"{
    value = local.provisioned_zone
}

output "positive_cost"{
    value = local.positive_cost
}

output "max_cost"{
    value = local.max_cost
}

output "min_cost"{
    value = local.min_cost
}

#output "credentials"{
   # value = var.credentials
#}