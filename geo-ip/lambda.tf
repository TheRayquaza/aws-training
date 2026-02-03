locals {
  get_function_name    = "geoip_get_function"
  update_function_name = "geoip_update_function"
}

resource "aws_cloudwatch_log_group" "get_logs" {
  name              = "/aws/lambda/${local.get_function_name}"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "update_logs" {
  name              = "/aws/lambda/${local.update_function_name}"
  retention_in_days = 7
}

data "archive_file" "geoip_get_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda_get/index.js"
  output_path = "${path.module}/lambda_get/index.zip"
}

resource "aws_lambda_function" "geoip_get_lambda" {
  function_name = "geoip_get_function"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  filename      = data.archive_file.geoip_get_zip.output_path
  vpc_config {
    subnet_ids         = [aws_subnet.main.id]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }
  depends_on = [
    # IAM
    aws_iam_role_policy_attachment.lambda_logs,
    aws_cloudwatch_log_group.get_logs,
    data.archive_file.geoip_get_zip,
    # DB
    aws_elasticache_cluster.stats_cache,
    aws_db_instance.stats_db,
    # VPC
    aws_vpc.main
  ]

  environment {
    variables = {
      REDIS_HOST = aws_elasticache_cluster.stats_cache.cluster_address
      REDIS_PORT = aws_elasticache_cluster.stats_cache.port
      # REDIS_PASSWORD = ""

      RDS_HOST = aws_db_instance.stats_db.address
      RDS_PORT = aws_db_instance.stats_db.port
      RDS_USER = aws_db_instance.stats_db.username
      RDS_PASSWORD = aws_db_instance.stats_db.password
      RDS_DATABASE = aws_db_instance.stats_db.db_name
    }
  }
}

data "archive_file" "geoip_update_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda_post/index.js"
  output_path = "${path.module}/lambda_post/index.zip"
}

resource "aws_lambda_function" "geoip_update_lambda" {
  function_name = "geoip_update_function"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  filename      = data.archive_file.geoip_update_zip.output_path
  vpc_config {
    subnet_ids         = [aws_subnet.main.id]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }
  depends_on = [
    # IAM
    aws_iam_role_policy_attachment.lambda_logs,
    aws_cloudwatch_log_group.update_logs,
    data.archive_file.geoip_update_zip,
    # DB
    aws_elasticache_cluster.stats_cache,
    aws_db_instance.stats_db,
    # VPC
    aws_vpc.main
  ]

  environment {
    variables = {
      REDIS_HOST = aws_elasticache_cluster.stats_cache.cluster_address
      REDIS_PORT = aws_elasticache_cluster.stats_cache.port
      #REDIS_PASSWORD = aws_secretsmanager_secret_version.redis_password.secret_string

      RDS_HOST = aws_db_instance.stats_db.address
      RDS_PORT = aws_db_instance.stats_db.port
      RDS_USER = aws_db_instance.stats_db.username
      RDS_PASSWORD = aws_db_instance.stats_db.password
      RDS_DATABASE = aws_db_instance.stats_db.db_name

      IPINFO_TOKEN = var.ipinfo_token
    }
  }
}

# Permissions for logs

resource "aws_iam_role" "lambda_role" {
  name = "geoip_counter_lambda_role"

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

# Permissions for API Gateway to invoke Lambda

resource "aws_lambda_permission" "apigw_lambda_get" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.geoip_get_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "apigw_lambda_update" {
  statement_id  = "AllowExecutionFromAPIGatewayUpdate"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.geoip_update_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}

# Permissions for VPC

resource "aws_iam_role_policy_attachment" "lambda_vpc_access" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# SG

resource "aws_security_group" "lambda_sg" {
  name        = "lambda_sg"
  description = "Security group for Lambda functions"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

## OUTPUTS ##

output "lambda_get_function_name" {
  description = "The name of the Lambda function for getting geoip counts"
  value       = aws_lambda_function.geoip_get_lambda.function_name
}

output "lambda_update_function_name" {
  description = "The name of the Lambda function for updating geoip counts"
  value       = aws_lambda_function.geoip_update_lambda.function_name
}

