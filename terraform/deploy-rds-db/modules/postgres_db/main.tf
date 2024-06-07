resource "aws_db_instance" "postgres_db" {
  instance_class                      = var.dbInstanceClass
  engine                              = "postgres"
  engine_version                      = "14.9"
  identifier                          = var.dbIdentifier
  apply_immediately                   = true
  username                            = "postgres"
  password                            = var.pass
  db_name                             = var.dbName
  customer_owned_ip_enabled           = false
  deletion_protection                 = false
  enabled_cloudwatch_logs_exports     = []
  iam_database_authentication_enabled = false
  allocated_storage                   = var.dbAllocatedStorage
  max_allocated_storage               = var.dbMaxAllocatedStorage
  storage_encrypted                   = true
  copy_tags_to_snapshot               = true
  monitoring_interval                 = 60
  performance_insights_enabled        = true
  publicly_accessible                 = true
  skip_final_snapshot                 = true
  monitoring_role_arn                 = var.monitoringRoleArn
  vpc_security_group_ids = [
    "sg-0fb2a14a7ea0d4f64"
  ]
  tags = {
    Environment  = var.environment
    db_name      = var.dbName
    organization = var.organization
  }
  backup_retention_period = 7
}

resource "aws_ssm_parameter" "rds_postgres_password" {
  name        = "/${var.organization}/${var.dbIdentifier}/${var.environment}/database/password/master"
  description = "password for ${var.dbIdentifier} ${var.environment}"
  type        = "SecureString"
  value       = var.pass

  tags = {
    environment = var.environment
    db_arn      = aws_db_instance.postgres_db.arn
  }
}
