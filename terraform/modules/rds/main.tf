resource "random_password" "database" {
  length  = 32
  special = false
}

resource "aws_security_group" "database" {
  name        = "${var.name}-db"
  description = "PostgreSQL access from ECS"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = var.private_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.name}-db"
  subnet_ids = var.subnet_ids
}

resource "aws_secretsmanager_secret" "database_password" {
  name = "${var.name}/database-password"
}

resource "aws_secretsmanager_secret_version" "database_password" {
  secret_id     = aws_secretsmanager_secret.database_password.id
  secret_string = random_password.database.result
}

resource "aws_db_instance" "this" {
  identifier                   = "${var.name}-postgres"
  engine                       = "postgres"
  engine_version               = "16"
  instance_class               = var.instance_class
  allocated_storage            = 20
  max_allocated_storage        = 100
  storage_type                 = "gp3"
  storage_encrypted            = true
  db_name                      = "cloudforge"
  username                     = "cloudforge"
  password                     = random_password.database.result
  port                         = 5432
  db_subnet_group_name         = aws_db_subnet_group.this.name
  vpc_security_group_ids       = [aws_security_group.database.id]
  publicly_accessible          = false
  multi_az                     = var.multi_az
  backup_retention_period      = 7
  deletion_protection          = var.deletion_protection
  skip_final_snapshot          = !var.deletion_protection

  lifecycle {
    prevent_destroy = false
  }
}
