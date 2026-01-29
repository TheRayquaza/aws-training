locals {
  get_function_name    = "visitor_get_function"
  update_function_name = "visitor_update_function"
}

resource "aws_cloudwatch_log_group" "get_logs" {
  name              = "/aws/lambda/${local.get_function_name}"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "update_logs" {
  name              = "/aws/lambda/${local.update_function_name}"
  retention_in_days = 7
}

data "archive_file" "visitor_get_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda_get/index.js"
  output_path = "${path.module}/lambda_get/index.zip"
}

resource "aws_lambda_function" "visitor_get_lambda" {
  function_name = "visitor_get_function"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  filename      = data.archive_file.visitor_get_zip.output_path
  depends_on = [
    aws_iam_role_policy_attachment.lambda_logs,
    aws_cloudwatch_log_group.get_logs,
    data.archive_file.visitor_get_zip
  ]

  environment {
    variables = {
        TABLE_NAME = aws_dynamodb_table.visitor_counter_table.name
    }
  }
}

data "archive_file" "visitor_update_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda_post/index.js"
  output_path = "${path.module}/lambda_post/index.zip"
}

resource "aws_lambda_function" "visitor_update_lambda" {
  function_name = "visitor_update_function"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  filename      = data.archive_file.visitor_update_zip.output_path
  depends_on = [
    aws_iam_role_policy_attachment.lambda_logs,
    aws_cloudwatch_log_group.update_logs,
    data.archive_file.visitor_update_zip
  ]

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.visitor_counter_table.name
    }
  }
}

# Permissions for logs

resource "aws_iam_role" "lambda_role" {
  name = "visitor_counter_lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Permissions for DynamoDB access

resource "aws_iam_policy" "dynamodb_access" {
  name        = "LambdaDynamoDBAccess"
  description = "Allow Lambda to read/write to the visitor table"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = [
        "dynamodb:GetItem",
        "dynamodb:UpdateItem",
        "dynamodb:PutItem"
      ]
      Resource = aws_dynamodb_table.visitor_counter_table.arn
    }]
  })
}

resource "aws_iam_role_policy_attachment" "attach_dynamo" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.dynamodb_access.arn
}

# Permissions for API Gateway to invoke Lambda

resource "aws_lambda_permission" "apigw_lambda_get" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.visitor_get_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "apigw_lambda_update" {
  statement_id  = "AllowExecutionFromAPIGatewayUpdate"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.visitor_update_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}

## OUTPUTS ##

output "lambda_get_function_name" {
  description = "The name of the Lambda function for getting visitor counts"
  value       = aws_lambda_function.visitor_get_lambda.function_name
}

output "lambda_update_function_name" {
  description = "The name of the Lambda function for updating visitor counts"
  value       = aws_lambda_function.visitor_update_lambda.function_name
}

