resource "aws_s3_bucket" "this" {
  bucket = local.bucket_name
  tags   = local.common_tags
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

resource "aws_security_group" "this" {
  name        = "${local.name_prefix}-sg"
  description = "Security group for ${local.name_prefix} resources"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidrs
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}

resource "aws_instance" "this" {
  count = var.instance_count

  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_config.instance_type
  subnet_id     = data.aws_subnets.default.ids[0]
  key_name      = var.key_name

  vpc_security_group_ids      = [aws_security_group.this.id]
  associate_public_ip_address = var.instance_config.public_ip
  monitoring                  = local.monitoring_enabled

  root_block_device {
    volume_size = var.instance_config.volume_size
    volume_type = "gp3"
    encrypted   = true
  }

  metadata_options {
    http_tokens = "required"
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-instance-${count.index + 1}"
  })

  provisioner "local-exec" {
    command = "echo Instance ${self.id} public IP: ${self.public_ip} >> instance_ips.txt"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "terraform_data" "env_trigger" {
  triggers_replace = {
    env = var.environment
  }

  provisioner "local-exec" {
    command = "echo Deployed environment: ${var.environment} >> environment_log.txt"
  }
}
