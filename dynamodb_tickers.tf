# DynamoDB table for ticker registry
resource "aws_dynamodb_table" "tickers" {
  name           = "${var.project_prefix}-tickers"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "symbol"

  attribute {
    name = "symbol"
    type = "S"
  }

  tags = {
    Name = "${var.project_prefix}-tickers-registry"
  }
}


