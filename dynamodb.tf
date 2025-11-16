# DynamoDB table for WebSocket connections
resource "aws_dynamodb_table" "connections" {
  name           = "${var.project_prefix}-connections"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "connectionId"

  attribute {
    name = "connectionId"
    type = "S"
  }

  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  tags = {
    Name = "${var.project_prefix}-connections"
  }
}

# DynamoDB table for trade history
resource "aws_dynamodb_table" "trades" {
  name           = "${var.project_prefix}-trades"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "symbol"
  range_key      = "timestamp"

  attribute {
    name = "symbol"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "N"
  }

  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  tags = {
    Name = "${var.project_prefix}-trades-history"
  }
}
