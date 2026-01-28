output "bucket_upload_images_name" {
  description = "The name of the S3 bucket"
  value       = aws_s3_bucket.upload-images.bucket
}

output "lambda_function_name" {
  description = "The name of the Lambda function"
  value       = aws_lambda_function.thumbnailer.function_name
}
