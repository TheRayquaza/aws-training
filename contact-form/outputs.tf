output "sns_topic_arn" {
  description = "The ARN of the SNS Topic"
  value       = aws_sns_topic.contact_requests.arn
}

output "lambda_function_name" {
  description = "The name of the Lambda function"
  value       = aws_lambda_function.contact_form_lambda.function_name
}

output "lambda_function_arn" {
  description = "The ARN of the Lambda function"
  value       = aws_lambda_function.contact_form_lambda.arn
}

output "contact_api_url" {
  description = "The URL to put in your fetch() call"
  value       = "${aws_api_gateway_stage.prod.invoke_url}/contact"
}
