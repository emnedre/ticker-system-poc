# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.project_prefix}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "${var.project_prefix}-ecs-cluster"
  }
}

# Security group for ECS tasks
resource "aws_security_group" "ecs_tasks" {
  name        = "${var.project_prefix}-ecs-tasks-sg"
  description = "Security group for ECS tasks"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "${var.project_prefix}-ecs-tasks-sg"
  }
}

# CloudWatch log group for producer
resource "aws_cloudwatch_log_group" "producer" {
  name              = "/ecs/${var.project_prefix}-producer"
  retention_in_days = 7

  tags = {
    Name = "${var.project_prefix}-producer-logs"
  }
}

# ECS task definition for trade producer
resource "aws_ecs_task_definition" "producer" {
  family                   = "${var.project_prefix}-producer"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn           = aws_iam_role.ecs_task.arn
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }

  container_definitions = jsonencode([
    {
      name  = "producer"
      image = "${aws_ecr_repository.producer.repository_url}:latest"
      
      environment = [
        {
          name  = "KINESIS_STREAM_NAME"
          value = aws_kinesis_stream.trades.name
        },
        {
          name  = "AWS_REGION"
          value = var.aws_region
        },
        {
          name  = "TRADE_FREQUENCY"
          value = tostring(var.trade_frequency)
        },
        {
          name  = "TICKERS_TABLE"
          value = aws_dynamodb_table.tickers.name
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.producer.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = {
    Name = "${var.project_prefix}-producer-task"
  }
}

# ECR repository for producer
resource "aws_ecr_repository" "producer" {
  name                 = "${var.project_prefix}-producer"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${var.project_prefix}-producer-ecr"
  }
}

# ECS service for producer
resource "aws_ecs_service" "producer" {
  name            = "${var.project_prefix}-producer"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.producer.arn
  desired_count   = var.producer_task_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  tags = {
    Name = "${var.project_prefix}-producer-service"
  }
}
