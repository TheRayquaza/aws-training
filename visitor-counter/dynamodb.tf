
resource "aws_dynamodb_table" "visitor_counter_table" {
  name         = "VisitorCounts"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "Page"

  attribute {
    name = "Page"
    type = "S"
  }
}

## OUTPUTS ##

output "dynamodb_table_name" {
  description = "The name of the DynamoDB table"
  value       = aws_dynamodb_table.visitor_counter_table.name
}
