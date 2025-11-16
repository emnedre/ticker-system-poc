variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "project_prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "ticker-system-poc"
}

variable "trade_frequency" {
  description = "Number of trades per second to generate"
  type        = number
  default     = 5
}

variable "producer_task_count" {
  description = "Number of producer tasks (tickers) to run"
  type        = number
  default     = 4
}


