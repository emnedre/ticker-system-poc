output "websocket_url" {
  description = "WebSocket API Gateway URL"
  value       = aws_apigatewayv2_stage.websocket.invoke_url
}

output "website_url" {
  description = "CloudFront distribution URL"
  value       = aws_cloudfront_distribution.website.domain_name
}

output "kinesis_stream_name" {
  description = "Kinesis stream name"
  value       = aws_kinesis_stream.trades.name
}

output "producer_task_definition" {
  description = "ECS task definition ARN for producer"
  value       = aws_ecs_task_definition.producer.arn
}

output "tickers_table" {
  description = "DynamoDB tickers table name"
  value       = aws_dynamodb_table.tickers.name
}

output "active_tickers_count" {
  description = "Number of producer tasks running"
  value       = var.producer_task_count
}
