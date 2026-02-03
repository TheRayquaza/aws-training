locals {
  css_files = sort(fileset(path.module, "website/dist/assets/styles*.css"))
  css_path  = length(local.css_files) > 0 ? local.css_files[0] : "not-found"
  js_files = sort(fileset(path.module, "website/dist/assets/scripts*.js"))
  js_path  = length(local.js_files) > 0 ? local.js_files[0] : "not-found"
}

resource "aws_s3_bucket" "website_bucket" {
  bucket_prefix = "geoip-website-"
}

resource "aws_s3_bucket_public_access_block" "block_public_access" {
  bucket                  = aws_s3_bucket.website_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_object" "index_html" {
  bucket       = aws_s3_bucket.website_bucket.id
  key          = "index.html"
  source       = "website/dist/index.html"
  content_type = "text/html"
}

resource "aws_s3_object" "css_styles" {
  bucket       = aws_s3_bucket.website_bucket.id
  key          = "assets/styles.css"
  source       = local.css_path
  content_type = "text/css"
}

resource "aws_s3_object" "js_styles" {
  bucket       = aws_s3_bucket.website_bucket.id
  key          = "assets/scripts.js"
  source       = local.js_path
  content_type = "application/javascript"
}

resource "aws_cloudfront_origin_access_control" "default" {
  name                              = "s3_oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name              = aws_s3_bucket.website_bucket.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.default.id
    origin_id                = "S3Origin"
  }

  enabled             = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3Origin"

    forwarded_values {
      query_string = false
      cookies { forward = "none" }
    }

    viewer_protocol_policy = "redirect-to-https"
  }

  restrictions {
    geo_restriction { restriction_type = "none" }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.website_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AllowCloudFrontServicePrincipalReadOnly"
        Effect   = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.website_bucket.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.s3_distribution.arn
          }
        }
      }
    ]
  })
}

output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.s3_distribution.domain_name
}

output "s3_bucket_name" {
  value = aws_s3_bucket.website_bucket.bucket
}

output "s3_bucket_index_url" {
  value = "http://${aws_s3_bucket.website_bucket.bucket}.s3-website-${var.region}.amazonaws.com/index.html"
}
