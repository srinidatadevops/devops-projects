locals {
  name = "${var.project_name}-${var.environment}"
}

resource "aws_security_group" "postgres" {
  name        = "${local.name}-postgres-sg"
  description = "Postgres access for the application"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = toset(var.allowed_security_group_ids)

    content {
      description     = "Postgres from EKS"
      from_port       = 5432
      to_port         = 5432
      protocol        = "tcp"
      security_groups = [ingress.value]
    }
  }

  tags = {
    Name = "${local.name}-postgres-sg"
  }
}

resource "aws_db_subnet_group" "this" {
  name       = "${local.name}-postgres-subnets"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "${local.name}-postgres-subnets"
  }
}

resource "aws_db_instance" "postgres" {
  identifier                   = "${local.name}-postgres"
  engine                       = "postgres"
  engine_version               = "16.3"
  instance_class               = "db.t3.micro"
  allocated_storage            = 20
  max_allocated_storage        = 100
  storage_type                 = "gp3"
  storage_encrypted            = true
  db_name                      = var.database_name
  username                     = var.database_username
  password                     = var.database_password
  db_subnet_group_name         = aws_db_subnet_group.this.name
  vpc_security_group_ids       = [aws_security_group.postgres.id]
  publicly_accessible          = false
  multi_az                     = false
  backup_retention_period      = 7
  deletion_protection          = false
  skip_final_snapshot          = true
  performance_insights_enabled = true
  apply_immediately            = true

  tags = {
    Name = "${local.name}-postgres"
  }
}
