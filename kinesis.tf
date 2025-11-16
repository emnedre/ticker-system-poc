# Kinesis Data Stream for trade events
resource "aws_kinesis_stream" "trades" {
  name             = "${var.project_prefix}-trades"
  shard_count      = 2  # 2 shards = 2 parallel Lambda executions (can only double at a time)
  retention_period = 24

  shard_level_metrics = [
    "IncomingBytes",
    "IncomingRecords",
    "OutgoingBytes",
    "OutgoingRecords",
  ]

  stream_mode_details {
    stream_mode = "PROVISIONED"
  }

  tags = {
    Name = "${var.project_prefix}-trades-stream"
  }
}
