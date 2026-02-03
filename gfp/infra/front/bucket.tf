resource "aws_s3_bucket" "website_bucket" {
  bucket_prefix = "gfp-website-"
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
  source       = var.html_path
  content_type = "text/html"
}

resource "aws_s3_object" "css_styles" {
  bucket       = aws_s3_bucket.website_bucket.id
  key          = "assets/${basename(var.css_path)}"
  source       = var.css_path
  content_type = "text/css"
}

resource "aws_s3_object" "js_styles" {
  bucket       = aws_s3_bucket.website_bucket.id
  key          = "assets/${basename(var.js_path)}"
  source       = var.js_path
  content_type = "application/javascript"
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.website_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AllowCloudFrontOAC"
        Effect   = "Allow"
        Principal = { Service = "cloudfront.amazonaws.com" }
        Action   = ["s3:GetObject", "s3:ListBucket"]
        Resource = [
          aws_s3_bucket.website_bucket.arn,
          "${aws_s3_bucket.website_bucket.arn}/*"
        ]
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.s3_distribution.arn
          }
        }
      }
    ]
  })
}