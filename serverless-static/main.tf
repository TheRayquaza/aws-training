provider "aws" {
  region = var.region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

# 1. The Bucket
resource "aws_s3_bucket" "test" {
    bucket_prefix = "my-test-site-"
}

resource "aws_s3_object" "index" {
  bucket = aws_s3_bucket.test.id
  key    = "index.html"
  content = <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>My Static Website</title>
</head>
<body>
    <h1>Welcome to My Static Website!</h1>
    <p>This is a simple static website hosted on S3 and served via CloudFront.</p>
</body>
</html>
EOF
  content_type = "text/html"
}

# 2. Block Public Access (Best Practice)
resource "aws_s3_bucket_public_access_block" "b" {
  bucket = aws_s3_bucket.test.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "allow_access_from_cloudfront" {
  bucket = aws_s3_bucket.test.id
  policy = data.aws_iam_policy_document.default.json
}

data "aws_iam_policy_document" "default" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.test.arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.s3_distribution.arn]
    }
  }
}

# 3. The CloudFront OAC
resource "aws_cloudfront_origin_access_control" "default" {
  name                              = "s3-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# 4. The Distribution
resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name              = aws_s3_bucket.test.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.default.id
    origin_id                = "myS3Origin"
  }

  enabled             = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "myS3Origin"

    viewer_protocol_policy = "redirect-to-https"
    
    forwarded_values {
      query_string = false
      cookies { forward = "none" }
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true # Use this if you don't have a domain ready
  }

  restrictions {
    geo_restriction { restriction_type = "none" }
  }
}
