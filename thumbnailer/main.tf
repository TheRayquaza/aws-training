provider "aws" {
  region = var.region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

# 1. The Bucket
resource "aws_s3_bucket" "upload-images" {
    bucket_prefix = "upload-images-"
    force_destroy = true
}

resource "aws_s3_bucket" "resized-thumbnails" {
    bucket_prefix = "resized-thumbnails-"
    force_destroy = true
}

# 2. Block Public Access (Best Practice)
resource "aws_s3_bucket_public_access_block" "b" {
  bucket = aws_s3_bucket.upload-images.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "b2" {
  bucket = aws_s3_bucket.resized-thumbnails.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 3. The Lambda Function
resource "aws_iam_role" "lambda_role" {
  name = "lambda_s3_thumbnailer_role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy.json
}

data "aws_iam_policy_document" "lambda_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "s3_access_policy" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

data "archive_file" "example" {
  type        = "zip"
  source_file = "${path.module}/lambda/index.js"
  output_path = "${path.module}/lambda/function.zip"
}

resource "aws_lambda_function" "thumbnailer" {
  function_name = "s3_thumbnailer_function"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  filename      = data.archive_file.example.output_path

  source_code_hash = filebase64sha256(data.archive_file.example.output_path)

  environment {
    variables = {
      RESIZED_BUCKET = aws_s3_bucket.resized-thumbnails.bucket
    }
  }
}

resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.thumbnailer.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.upload-images.arn
}

# Create the trigger
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.upload-images.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.thumbnailer.arn
    events              = ["s3:ObjectCreated:*"]
    filter_suffix       = ".jpg" # only resize JPEGs
  }

  depends_on = [aws_lambda_permission.allow_bucket]
}
