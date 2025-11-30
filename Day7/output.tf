# Task 10: Mixed Type Constraints
output "deployment_summary" {
  value = {
    environment    = var.environment
    instance_count = var.server_config.instance_count
    name_tag       = var.instance_tags["Name"]
  }
}