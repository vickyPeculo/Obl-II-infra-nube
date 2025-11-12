variable "bucket_name" {
  type    = string
  default = "certeza360-sitio-estatico"
}

variable "tags" {
  type = map(string)
  default = {
    Project = "Certeza360"
    Module  = "static-site"
  }
}

resource "random_string" "suffix" {
  length  = 6
  upper   = false
  numeric = true
  special = false
}

resource "aws_s3_bucket" "website" {
  bucket = "${var.bucket_name}-${random_string.suffix.result}"
  tags   = merge(var.tags, { Name = "s3-website" })
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.website.id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = false
  restrict_public_buckets = true
}

resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.website.id
  key          = "index.html"
  content_type = "text/html"
  content      = file("${path.module}/index.html")
  etag         = md5(file("${path.module}/index.html"))
}

resource "aws_s3_object" "error" {
  bucket       = aws_s3_bucket.website.id
  key          = "error.html"
  content_type = "text/html"
  content      = file("${path.module}/error.html")
  etag         = md5(file("${path.module}/error.html"))
}

resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "oac-${var.bucket_name}-${random_string.suffix.result}"
  description                       = "OAC para S3 privado del sitio estático"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "website" {
  enabled             = true
  is_ipv6_enabled     = true
  price_class         = "PriceClass_100"
  default_root_object = "index.html"

  origin {
    domain_name              = aws_s3_bucket.website.bucket_regional_domain_name
    origin_id                = "S3Origin-${var.bucket_name}-${random_string.suffix.result}"
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  default_cache_behavior {
    target_origin_id       = "S3Origin-${var.bucket_name}-${random_string.suffix.result}"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true
    default_ttl            = 3600
    min_ttl                = 0
    max_ttl                = 86400
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction { restriction_type = "none" }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
    minimum_protocol_version       = "TLSv1.2_2021"
  }

  tags = merge(var.tags, { Name = "cloudfront-website" })
}

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket_policy" "allow_cf_oac" {
  bucket = aws_s3_bucket.website.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "AllowCloudFrontServicePrincipalReadOnly"
        Effect    = "Allow"
        Principal = { Service = "cloudfront.amazonaws.com" }
        Action    = ["s3:GetObject"]
        Resource  = "${aws_s3_bucket.website.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.website.arn
          }
        }
      }
    ]
  })
  depends_on = [aws_s3_bucket_public_access_block.this]
}

output "cloudfront_domain" {
  value = "https://${aws_cloudfront_distribution.website.domain_name}"
}

output "bucket_name" {
  value = aws_s3_bucket.website.bucket
}
