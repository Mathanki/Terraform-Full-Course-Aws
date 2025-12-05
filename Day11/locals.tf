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
    name = "port-${port}"
    port = port
    description = "Allow traffic on port ${port}"
  }]

  instance_size = lookup(var.instance_sizes, var.environment, "t2.micro")
}
