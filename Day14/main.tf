# S3 bucket for static website hosting
resource "aws_s3_bucket" "my-static-website" {
  bucket = var.bucket_name
}

# Make S3 bucket private
resource "aws_s3_bucket_public_access_block" "my-static-website-acess" {
  bucket = aws_s3_bucket.my-static-website.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Origin Access Control for CloudFront (Recommended over OAI)
resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "oac-${var.bucket_prefix}"
  description                       = "OAC for static website"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# Bucket Policy
resource "aws_s3_bucket_policy" "allow_cloudfront" {
  bucket = aws_s3_bucket.my-static-website.id

  # Explicit dependency (using resource name, not attribute)
  depends_on = [aws_s3_bucket_public_access_block.my-static-website-acess]

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "AllowCloudFrontServicePrincipal",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "cloudfront.amazonaws.com"
        },
        "Action" : [
          "s3:GetObject"
        ],
        "Resource" : "${aws_s3_bucket.my-static-website.arn}/*", # access all the objects inside that bucket
        "Condition" : {
          "StringEquals" : {
            "AWS:SourceArn" : "${aws_cloudfront_distribution.s3_distribution.arn}" # reference to CloudFront distribution
          }
        }
      }
    ]
  })
}

# Upload the file to s3 bucket
resource "aws_s3_object" "object" {
  # Get all the files - html, css, js
  for_each = fileset("${path.module}/www", "**/*")
  bucket   = aws_s3_bucket.my-static-website.id
  key      = each.value
  source   = "${path.module}/www/${each.value}"

  etag = filemd5("${path.module}/www/${each.value}") # unique hash

  # Lookup for accepting only certain files based on extension
  # Fixed: Use regex to properly extract file extension
  content_type = lookup({
    "html" = "text/html"
    "css"  = "text/css"
    "js"   = "application/javascript"
    "jpeg" = "image/jpeg"
    "png"  = "image/png"
    "gif"  = "image/gif"
    "svg"  = "image/svg+xml"
    "ico"  = "image/x-icon"
    "jpg"  = "image/jpeg"
    "txt"  = "text/plain"
    "json" = "application/json"
    "xml"  = "application/xml"
    "pdf"  = "application/pdf"
  }, regex("\\.[^.]+$", each.value) != null ? replace(regex("\\.[^.]+$", each.value), ".", "") : "txt", "application/octet-stream")
}

# ACM Certificate for HTTPS (must be in us-east-1 for CloudFront)
resource "aws_acm_certificate" "cert" {
  provider                  = aws.us_east_1 # CloudFront requires certificates in us-east-1
  domain_name               = var.domain_name
  validation_method         = "DNS"
  subject_alternative_names = ["*.${var.domain_name}"]

  # This lifecycle block ensures a new certificate is issued before the old one is destroyed,
  # preventing downtime if the certificate needs to be replaced (e.g., new SANs added).
  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "CloudFront-Certificate-${var.domain_name}"
  }
}

resource "aws_route53_zone" "main" {
  name = var.domain_name
  tags = var.common_tags
}

resource "aws_route53_record" "root_a" {
  zone_id = aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "www_a" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "www.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}

# Route 53 record for ACM certificate validation
resource "aws_route53_record" "cert_validation" {

  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }
  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.main.zone_id
}

# ACM Certificate validation
resource "aws_acm_certificate_validation" "cert_validation" {
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
  # The timeout can be increased if DNS propagation takes longer
  timeouts {
    create = "2h"
  }
}


# CloudFront Distribution
resource "aws_cloudfront_distribution" "s3_distribution" {
  provider = aws.us_east_1
  depends_on = [
    aws_s3_bucket.my-static-website,
    aws_cloudfront_origin_access_control.oac,
    aws_acm_certificate_validation.cert_validation
  ]

  # Basic Settings
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "${var.domain_name} distribution"
  default_root_object = "index.html"
  http_version        = "http2and3" # Recommended modern HTTP version
  price_class         = "PriceClass_100"

  # Domain Names (Aliases)
  aliases = [
    var.domain_name,
    "www.${var.domain_name}"
  ]

  # ---  Origin Configuration (Connection to S3) ---
  origin {
    # Point to the S3 bucket's regional domain name (NOT the website endpoint)
    domain_name = aws_s3_bucket.my-static-website.bucket_regional_domain_name
    origin_id   = "${var.bucket_name}-origin"
    # Securely connect to the private S3 bucket using OAC
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  # ---  Default Cache Behavior ---
  default_cache_behavior {
    target_origin_id = "${var.bucket_name}-origin"
    # Use the AWS Managed Caching Policy (Standard)
    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"
    # Force all HTTP traffic to HTTPS
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }
  # Viewer Certificate (HTTPS/SSL Configuration) ---
  viewer_certificate {
    # Use the ARN of the validated ACM certificate
    acm_certificate_arn      = aws_acm_certificate_validation.cert_validation.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
  tags = var.common_tags
}
