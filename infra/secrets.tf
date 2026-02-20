# AWS Secrets Manager for RDS credentials
resource "aws_secretsmanager_secret" "rds_credentials" {
  name        = "resume-rds-credentials"
  description = "RDS PostgreSQL credentials for Resume API"
}

resource "aws_secretsmanager_secret_version" "rds_credentials" {
  secret_id = aws_secretsmanager_secret.rds_credentials.id
  secret_string = jsonencode({
    username = var.db_username
    password = local.db_password
    host     = aws_db_instance.postgres.address
    port     = 5432
    database = var.db_name
    connectionString = "Host=${aws_db_instance.postgres.address};Port=5432;Database=${var.db_name};Username=${var.db_username};Password=${local.db_password}"
  })
}

output "secrets_manager_arn" {
  description = "ARN of the Secrets Manager secret"
  value       = aws_secretsmanager_secret.rds_credentials.arn
}
