output "bucket_name" {
  description = "The name of the S3 bucket"
  value       = aws_s3_bucket.test.bucket
}

output "cloudfront_domain_name" {
  description = "The domain name of the CloudFront distribution"
  value       = aws_cloudfront_distribution.s3_distribution.domain_name 
}
