locals {
  name_prefix = "p3-${var.environment}"
}

resource "aws_db_subnet_group" "this" {
  name       = "${local.name_prefix}-db-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = merge(var.tags, { Name = "${local.name_prefix}-db-subnet-group", Environment = var.environment })
}

resource "aws_security_group" "rds" {
  name        = "${local.name_prefix}-rds-sg"
  description = "Security group for RDS — only accepts MySQL from instances SG"
  vpc_id      = var.vpc_id

  ingress {
    description     = "MySQL from app instances"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [var.allowed_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${local.name_prefix}-rds-sg", Environment = var.environment })
}

resource "aws_db_instance" "this" {
  identifier        = "${local.name_prefix}-db"
  engine            = "mysql"
  engine_version    = "8.0"
  instance_class    = var.instance_class
  db_name           = var.db_name
  username          = var.db_username
  password          = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  allocated_storage = 20
  storage_type      = "gp3"
  storage_encrypted = true

  skip_final_snapshot = true

  tags = merge(var.tags, { Name = "${local.name_prefix}-db", Environment = var.environment })
}
