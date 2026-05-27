resource "aws_ecr_repository" "this" {
  name         = "${local.name_prefix}-app"
  force_delete = true

  image_scanning_configuration {
    scan_on_push = true
  }

  lifecycle {
    prevent_destroy = true
  }

  tags = local.common_tags
}

resource "aws_ecs_cluster" "this" {
  name = "${local.name_prefix}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = local.common_tags
}

resource "aws_ecs_cluster_capacity_providers" "this" {
  cluster_name = aws_ecs_cluster.this.name

  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 1
  }
}

# dynamic block: iterates over a list of ports to generate ingress rules
resource "aws_security_group" "tasks" {
  name        = "${local.name_prefix}-ecs-tasks-sg"
  description = "Security group for ECS tasks"
  vpc_id      = data.aws_vpc.default.id

  dynamic "ingress" {
    for_each = var.ingress_ports
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}

# templatefile() reads the .tpl file and substitutes all ${variable} placeholders at plan time
resource "aws_ecs_task_definition" "this" {
  family                   = "${local.name_prefix}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn

  container_definitions = templatefile("${path.module}/templates/task-definition.json.tpl", {
    container_name = var.app_name
    image_uri      = "${aws_ecr_repository.this.repository_url}:latest"
    container_port = var.container_port
    log_group      = aws_cloudwatch_log_group.this.name
    aws_region     = var.aws_region
  })

  tags = local.common_tags
}

resource "aws_ecs_service" "this" {
  name            = "${local.name_prefix}-service"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = data.aws_subnets.default.ids
    security_groups  = [aws_security_group.tasks.id]
    assign_public_ip = true
  }

  # prevents Terraform from reverting task definition to an older revision
  # when deployments update the image outside of Terraform
  lifecycle {
    ignore_changes = [task_definition]
  }

  tags = local.common_tags
}
