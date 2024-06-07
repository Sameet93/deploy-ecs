resource "aws_db_instance" "mysql_db" {
  engine                              = "mysql"
  engine_version                      = "8.0.28"
  identifier                          = var.dbIdentifier
  username                            = "root"
  instance_class                      = var.dbInstanceClass
  apply_immediately                   = true
  availability_zone                   = "eu-west-1a"
  customer_owned_ip_enabled           = false
  deletion_protection                 = true
  enabled_cloudwatch_logs_exports     = []
  iam_database_authentication_enabled = false
  allocated_storage                   = var.dbAllocatedStorage
  max_allocated_storage               = var.dbMaxAllocatedStorage
  storage_encrypted                   = true
  copy_tags_to_snapshot               = true
  monitoring_interval                 = 60
  monitoring_role_arn                 = var.monitoringRoleArn
  performance_insights_enabled        = true
  publicly_accessible                 = true
  skip_final_snapshot                 = true
  password                            = var.pass
  vpc_security_group_ids = [
    "sg-0dddb37d88a43319a"
  ]
  tags = {
    environment  = var.environment
    organization = var.organization
  }
  backup_retention_period = 7
}

resource "aws_ssm_parameter" "ssm_parameter" {
  name        = "/${var.organization}/${var.dbIdentifier}/${var.environment}/database/password/master"
  description = "password for ${var.dbIdentifier} ${var.environment}"
  type        = "SecureString"
  value       = var.pass

  tags = {
    environment = var.environment
    db_arn      = aws_db_instance.mysql_db.arn
  }
}
