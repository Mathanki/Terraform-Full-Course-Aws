
# Day 14: Day 14: Static Website Hosting On AWS with Terraform | #30DaysOfAWSTerraform

This articale demonstrates how to deploy a fully functional static website on AWS using Terraform. It covering essential services such as S3 for storage, CloudFront for content delivery, and Route 53 for domain management. Each step is explained in detail.

![](day-14-static/083c31f7-2333-4c77-8a58-91dc924d2232.png)

This architecture illustrates the flow of hosting a static website on AWS using Route 53, CloudFront, S3 and Certificate Manager. Here’s how it works:

**Client (End User):** The client is the end user who attempts to access the website through a browser.

When the user enters the domain name, the very first action performed is a **DNS lookup** to determine where the request should be routed.

**Route 53 (DNS Resolution):** Amazon Route 53 acts as the DNS service for the domain.

When the DNS query is triggered, Route 53 responds by directing the request to the corresponding CloudFront distribution. This ensures that the website loads from the nearest edge location for optimal performance.

**AWS Certificate Manager (TLS/SSL Certificates)**: AWS Certificate Manager issues and manages SSL/TLS certificates used to secure the website. The certificate enables encrypted HTTPS communication, protecting data exchanged between the client and CloudFront. CloudFront retrieves the certificate from ACM to enforce secure, HTTPS-only access across all edge locations.

**CloudFront Distribution (Content Delivery Layer) :**CloudFront serves as the global content delivery network. Once Route 53 resolves the domain, the user’s request is routed to CloudFront, which performs one of two actions:

-   Serves cached content directly from the nearest edge location for faster loading.
    
-   Fetches content from the S3 origin when the requested object is not cached.
    

CloudFront also applies the SSL certificate issued by ACM to maintain a secure, encrypted connection with the client.

**CloudFront OAC + S3 Bucket Policy:** Origin Access Control (OAC) provides a secure and modern way to control access between CloudFront and an Amazon S3 bucket. With OAC, the S3 bucket remains completely private, and only the designated CloudFront distribution is permitted to retrieve objects from it.

Instead of relying on the older OAI method, OAC offers enhanced security and simplified management.

By applying the appropriate S3 bucket policy, access is tightly restricted so that:

-   The bucket is not publicly accessible
    
-   Only CloudFront through its OAC can read objects
    
-   All requests reaching the bucket originate from a trusted CloudFront distribution
    

This ensures that static website content is delivered securely while protecting the S3 bucket from unauthorized access.

**S3 Bucket**: Amazon S3 serves as the storage location for all website assets, including HTML, CSS, JavaScript, and image files. The bucket is configured as private, ensuring that no one can access its contents directly from the internet. Access is allowed only through CloudFront, which uses Origin Access Control (OAC) to securely request and retrieve objects from the bucket.

The website’s frontend resources—HTML pages, stylesheets, scripts, and media files—are uploaded to this private S3 bucket. CloudFront then delivers these files to users, providing fast, secure, and globally distributed access. By storing content in S3 and serving it through CloudFront, the architecture ensures both strong security and high performance.

## Putting the Architecture Into Action

### Setting up the AWS Provider**

Terraform providers define which cloud platform or service Terraform will interact with and allow Terraform to communicate with that platform’s API.

In this project, two AWS providers are configured:

-   Primary provider**:** Handles general AWS resources such as S3, CloudFront, and Route 53.
    
-   Secondary provide**r:** Specifically used for AWS Certificate Manager (ACM), which must operate in the `us-east-1` region for CloudFront to use its certificates.
    

This setup ensures Terraform can seamlessly provision all required AWS services across the appropriate regions.

```
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
  backend "s3" {
    bucket         = "tech-demo-mathanki-terraform-state"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    use_lockfile   = true
  }
}

# The default provider configuration (for S3, Route 53, etc.)
provider "aws" {
  region = var.aws_region
}

# The explicit alias required for ACM/CloudFront (MUST be us-east-1)
provider "aws" {
  alias  = "us_east_1" # <--- Must be a string literal, not a variable
  region = "us-east-1"
}
```

### Setting Up the Domain Using Route 53

Amazon Route 53 uses a **Hosted Zone** to manage how traffic is routed for a specific domain, such as [cloudcoachguru.in](http://cloudcoachguru.in/). A hosted zone contains all the DNS records required to direct users to the correct AWS resources—whether it's a CloudFront distribution, load balancer, or an API endpoint.

When a domain is registered or managed in Route 53, a hosted zone is created (or updated) to store these DNS configurations. This ensures that any request to your domain is resolved accurately and directed to the intended destination.

```
resource "aws_route53_zone" "main" {
  name = var.domain_name
  tags = var.common_tags
}
```

aws\_route53\_zone "main": This resource creates a hosted zone in Route 53 for the specified domain. It serves as the central container for all DNS records associated with the domain. The name attribute defines the domain itself, and additional tags help with organization and management.

### Generate SSL Certificate

To enable secure HTTPS access for the website, an SSL certificate is required. This section provisions a certificate using AWS Certificate Manager (ACM), ensuring encrypted communication between users and the CloudFront distribution.

```
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
```

**aws\_acm\_certificate:** The aws\_acm\_certificate resource is responsible for provisioning an SSL/TLS certificate from AWS Certificate Manager (ACM), which is essential for enabling HTTPS on your CloudFront distribution. It is configured to use DNS validation and covers both the primary domain and all subdomains using a wildcard entry. A strict requirement for use with CloudFront is enforced by explicitly using the [aws.us](http://aws.us/)\_east\_1 provider alias, ensuring the certificate is created in the US East (N. Virginia) region. Furthermore, the lifecycle block is set to create\_before\_destroy, which guarantees that any future certificate updates or replacements occur without causing service downtime

### Create the DNS Validation Records in Route 53

This uses a for\_each loop to automatically create the required CNAME records. for every domain/subdomain needing validation ([cloudcoachguru.com](http://cloudcoachguru.com/) and \*.[cloudcoachguru.com](http://cloudcoachguru.com/)).

```
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
```

**aws\_route53\_record.cert\_validation**: This resource, aws\_route53\_record.cert\_validation, is responsible for automatically creating the necessary DNS records in your Route 53 Hosted Zone to complete the ACM certificate validation. It uses a for\_each loop to iterate over the validation details provided by the aws\_acm\_certificate resource, which typically includes one record for the root domain and one for the wildcard domain. For each domain needing validation, it creates a new CNAME record using the name, value, and type generated by ACM, setting a low TTL (60 seconds) to help speed up propagation. This automated step proves to ACM that you own the domain, allowing the certificate to be successfully issued

### Wait for ACM Validation to Complete

This resource depends on the DNS records being created and then blocks.

```
resource "aws_acm_certificate_validation" "cert_validation" {
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
  # The timeout can be increased if DNS propagation takes longer
  timeouts {
    create = "40m"
  }
}
```

**aws\_acm\_certificate\_validation:** The aws\_acm\_certificate\_validation resource acts as a necessary waiter and final confirmation step for the ACM certificate. It explicitly tells Terraform to pause the deployment until AWS Certificate Manager confirms that the required DNS records have propagated and the certificate has been successfully issued and validated. This resource requires the ARN of the certificate being validated and the list of Fully Qualified Domain Names (FQDNs) of the validation records created in Route 53. By waiting for the certificate to be fully active, it prevents other resources, like the CloudFront distribution, from attempting to use an incomplete or pending certificate

### S3 Bucket creation

We will create an Amazon S3 bucket to store and manage all static assets for the website, such as HTML, CSS, JavaScript, and images. This bucket acts as the origin for CloudFront, providing a secure and reliable storage layer for the site’s content.

```
resource "aws_s3_bucket" "my-static-website" {
  bucket = var.bucket_name
}
```

### **Public Access Restrictions**

This configuration strengthens the bucket’s security by preventing any form of public access. It blocks public ACLs, ignores public policies, and ensures that all content stored in the bucket remains private. Only authorized services—such as CloudFront through OAC can access the bucket’s objects.

```
resource "aws_s3_bucket_public_access_block" "my-static-website-acess" {
  bucket = aws_s3_bucket.my-static-website.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
```

### **Create Origin Access Control**

The Origin Access Control (OAC) resource is the modern, recommended way to secure the connection between an Amazon CloudFront distribution and an Amazon S3 bucket that is used as an origin. It ensures that the S3 content can only be accessed through the specified CloudFront distribution, preventing users from bypassing CloudFront and accessing the S3 bucket directly.

The primary role of this OAC resource is to generate an identity that is then referenced by the CloudFront Distribution and used in an S3 Bucket Policy to allow CloudFront to fetch objects while denying public access to the bucket itself

```
resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "oac-${var.bucket_prefix}"
  description                       = "OAC for static website"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}
```

The OAC is then integrated into the S3 bucket policy, granting the CloudFront service principal permission to perform s3:GetObject operations—but only for the specific CloudFront distribution associated with the defined ARN.

```
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
```

### **Upload your website files to S3**

When deploying a static website, it’s important to upload your site assets to the S3 bucket in a reliable and automated manner. The Terraform configuration below streamlines this process, ensuring that all website files are transferred to the bucket efficiently and consistently during deployment.

```
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
```

In the aws\_s3\_object resource, Terraform loops through every file inside the local ./www directory and uploads it to the configured S3 bucket. The for\_each argument allows Terraform to process each file individually, ensuring that all website assets are deployed automatically with every run.

Additionally, the configuration detects the appropriate content\_type for each file, ensuring that assets like HTML, CSS, JavaScript, and images are served correctly by CloudFront. This not only preserves website’s structure in the cloud but also improves loading performance and overall user experience.

### **Configure CloudFront Distribution**

For any online platform, fast and secure content delivery is essential. AWS CloudFront makes this possible by distributing content across a global network of edge locations, ensuring reduced latency and improved performance for users everywhere.

Beyond speed and security, CloudFront provides powerful capabilities such as edge-based processing, intelligent content optimization, and in-depth analytics making it a robust and feature-rich solution for modern content delivery requirements.

```
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

  #Origin Configuration (Connection to S3) 
  origin {
    # Point to the S3 bucket regional domain name (NOT the website endpoint)
    domain_name = aws_s3_bucket.my-static-website.bucket_regional_domain_name
    origin_id   = "${var.bucket_name}-origin"
    # Securely connect to the private S3 bucket using OAC
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  # ---  Default Cache Behavior ---
  default_cache_behavior {
    target_origin_id       = "${var.bucket_name}-origin"
    # Use the AWS Managed Caching Policy (Standard)
    cache_policy_id        = "658327ea-f89d-4fab-a63d-7e88639e58f6"
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
```

**origin:**

Specifies the source from which CloudFront retrieves content. In this setup, the origin is our private S3 bucket, which stores all website assets that CloudFront will deliver to users.

**default\_cache\_behavior:**

Defines how CloudFront handles requests, including caching rules, allowed HTTP methods, and security settings. This configuration enforces HTTPS delivery for all content.

**aliases:**

Lists the custom domain names that point to this CloudFront distribution. By configuring aliases, users can access the website through a friendly domain instead of the default CloudFront URL.

**restrictions:**

Controls geographic access to the distribution. In this setup, geo-restriction is disabled, meaning the content is available globally without limiting access based on location.

**viewer\_certificate:**

Links the AWS Certificate Manager SSL/TLS certificate to the distribution. This enables secure HTTPS communication between users and CloudFront, ensuring encrypted and trusted access to the website.

### Route 53 A-Records

The final step is to point your domain names to the CloudFront distribution using an **Alias A Record** in Route 53.

```
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
```

aws\_route53\_record.root\_a (Root Domain Record) This resource creates the essential DNS record for your primary domain, such as [cloudcoachguru.com](http://cloudcoachguru.com/) (the root domain). It uses an Alias A Record to point this base domain name directly to your CloudFront Distribution (aws\_cloudfront\_distribution.s3\_distribution). An Alias record is a Route 53 feature that functions like a seamless pointer, allowing the root domain to resolve to an AWS resource without requiring a fixed IP address. When a user types your domain name, this record ensures they are immediately directed to the geographically closest AWS edge location managed by CloudFront, enabling fast, secure, and HTTPS-enabled access to your website content stored in S3.

aws\_route53\_record.www\_a (WWW Subdomain Record) This resource is nearly identical to the root record, but it specifically handles the common www subdomain (e.g., [www.cloudcoachguru.com](http://www.cloudcoachguru.com/)). By setting the name to "www.${var.domain\_name}", it maps the www version of your domain to the exact same CloudFront Distribution. This ensures that users can access your website whether they type [cloudcoachguru.com](http://cloudcoachguru.com/) or [www.cloudcoachguru.com](http://www.cloudcoachguru.com/). Both records are necessary because users may use either format, and both must point to the CloudFront distribution so it can serve the content and handle any necessary redirects (like forcing all traffic from www to the root domain or vice versa).

## Conclusion

By integrating multiple AWS services through Terraform, this project delivers a streamlined, serverless hosting architecture that is secure, scalable, and highly efficient. Each component—from S3 and CloudFront to Route 53 and ACM—works together to provide a seamless deployment workflow and robust user experience.

## Reference

https://www.youtube.com/watch?v=bK6RimAv2nQ&list=PLl4APkPHzsUXcfBSJDExYR-a4fQiZGmMp&index=16