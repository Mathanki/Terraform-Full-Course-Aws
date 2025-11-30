
#Create S3 bucket
# Task 1: String Constraint
resource "aws_s3_bucket" "example" {
  bucket = "${var.environment}-my-demo-bucket"
  #Task 6 Set(string)
  region = var.region
}

#Create EC2 Instance
resource "aws_instance" "web_server" {
  ami           = "ami-0e8459476fed2e23b"
  #list type : instance type
  #Task 5: List(string)
  instance_type = var.allowed_instance_types[0]
  lifecycle {
    precondition {
      condition     = contains(var.allowed_instance_types, var.allowed_instance_types[0])
      error_message = "The selected instance type: ${var.allowed_instance_types[0]} is not explicitly allowed by organizational policy. Check the 'allowed_instance_types' variable list."
    }
  }
  # string type: region
  #region = var.region

  # set type: regin
  #Task 6: Set(string)
  #region = tolist(var.allowed_region)[0]  # Need to convert to list to access the indices

  #object type: server config
  #Task 9: Object
  region= var.server_config.region

  #Task 2: Number Constraint
  # Number type: Instance count
  #count = var.instance_count

  #Task 9: Object
  count = var.server_config.instance_count

  # Bool type: Enable monitoring and public IP
  #Task 3: Boolean Constraint 
  #monitoring = var.enable_monitoring

  #Task 9: Object
  monitoring = var.server_config.monitoring

  associate_public_ip_address = var.associate_public_ip
  # map type : instance tag
  #Task 7: Map(string)
  tags = var.instance_tags
}

resource "aws_vpc" "my_vpc" {
  cidr_block = var.allowed_cidr_blocks[0]
  tags       = var.instance_tags
}
# Task 4: List(string) Constraint (CIDR blocks)
resource "aws_subnet" "subnet1" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = var.allowed_cidr_blocks[1]
  tags = var.instance_tags
}
resource "aws_subnet" "subnet2" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = var.allowed_cidr_blocks[2]
  tags = var.instance_tags
}

resource "aws_security_group" "allow_tls" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic and all outbound traffic"
  # map type : instance tag
  tags = var.instance_tags
}

resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv4" {
  security_group_id = aws_security_group.allow_tls.id
  # List type: Cidr ipv4
  #Task 4: List(string)
  cidr_ipv4         = var.allowed_cidr_blocks[0]
  # tuple type: ingress_values
  #Task 8: Tuple
  from_port         = var.ingress_values[0]
  ip_protocol       = var.ingress_values[1]
  to_port           = var.ingress_values[2]
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}



