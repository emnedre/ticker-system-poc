# Lambda function for WebSocket $connect
resource "aws_lambda_function" "connect" {
  filename         = "lambda/connect.zip"
  function_name    = "${var.project_prefix}-connect"
  role            = aws_iam_role.lambda.arn
  handler         = "connect.handler"
  source_code_hash = filebase64sha256("lambda/connect.zip")
  runtime         = "python3.13"
  timeout         = 30

  environment {
    variables = {
      CONNECTIONS_TABLE = aws_dynamodb_table.connections.name
    }
  }

  tags = {
    Name = "${var.project_prefix}-connect-lambda"
  }
}

# Lambda function for WebSocket $disconnect
resource "aws_lambda_function" "disconnect" {
  filename         = "lambda/disconnect.zip"
  function_name    = "${var.project_prefix}-disconnect"
  role            = aws_iam_role.lambda.arn
  handler         = "disconnect.handler"
  source_code_hash = filebase64sha256("lambda/disconnect.zip")
  runtime         = "python3.13"
  timeout         = 30

  environment {
    variables = {
      CONNECTIONS_TABLE = aws_dynamodb_table.connections.name
    }
  }

  tags = {
    Name = "${var.project_prefix}-disconnect-lambda"
  }
}

# Lambda function for processing Kinesis stream
resource "aws_lambda_function" "processor" {
  filename         = "lambda/processor.zip"
  function_name    = "${var.project_prefix}-processor"
  role            = aws_iam_role.lambda.arn
  handler         = "processor.handler"
  source_code_hash = filebase64sha256("lambda/processor.zip")
  runtime         = "python3.13"
  timeout         = 60
  memory_size     = 512

  environment {
    variables = {
      TRADES_TABLE      = aws_dynamodb_table.trades.name
      CONNECTIONS_TABLE = aws_dynamodb_table.connections.name
      WEBSOCKET_API_ENDPOINT = "https://${aws_apigatewayv2_api.websocket.id}.execute-api.${var.aws_region}.amazonaws.com/${var.environment}"
    }
  }

  tags = {
    Name = "${var.project_prefix}-processor-lambda"
  }
}

# Event source mapping for Kinesis to Lambda
resource "aws_lambda_event_source_mapping" "kinesis_to_processor" {
  event_source_arn  = aws_kinesis_stream.trades.arn
  function_name     = aws_lambda_function.processor.arn
  starting_position = "LATEST"
  batch_size        = 10  # Smaller batches = more frequent invocations
  
  # No batch window - process immediately
  
  # Parallelization factor - process multiple batches concurrently per shard
  parallelization_factor = 10

  depends_on = [aws_iam_role_policy.lambda_custom]
}
