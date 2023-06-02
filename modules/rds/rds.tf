# ***************************************
# RDS
# ***************************************
resource "aws_db_instance" "oracle_rds" {
  # RDS info
  db_name                         = var.db_name
  identifier                      = var.db_identifier
  engine                          = var.db_engine
  engine_version                  = var.db_engine_version
  username                        = var.db_username
  password                        = random_password.oracle_pg_admin_password.result
  parameter_group_name            = var.ssl_required && var.db_engine == "postgres" ? aws_db_parameter_group.oracle_rds_parameter_group[0].name : null
  multi_az                        = var.db_multi_az
  enabled_cloudwatch_logs_exports = var.db_log_exports

  # Networking & Security
  port                                = var.db_port
  db_subnet_group_name                = var.db_subnet_group_name
  vpc_security_group_ids              = concat([aws_security_group.rds_security_group.id], var.vpc_security_group_ids)
  iam_database_authentication_enabled = var.iam_database_authentication_enabled

  # Hardware, Storage & Backup
  storage_type            = var.rds_storage_type
  allocated_storage       = var.rds_storage_size 
  max_allocated_storage   = var.rds_max_storage_size
  instance_class          = var.rds_instance_type
  storage_encrypted       = true
  skip_final_snapshot     = true
  backup_retention_period = 30
}

# ***************************************
# RDS - Read Replica
# ***************************************
resource "aws_db_instance" "oracle_rds_read_replica" {
  count = var.rds_read_replica ? 1 : 0

  # Replica ID
  replicate_source_db = aws_db_instance.oracle_rds.identifier

  # RDS info
  identifier                      = "${var.db_identifier}-read-replica"
  enabled_cloudwatch_logs_exports = var.db_log_exports

  # Networking & Security
  port                                = var.db_port
  vpc_security_group_ids              = concat([aws_security_group.rds_security_group.id], var.vpc_security_group_ids)
  iam_database_authentication_enabled = var.iam_database_authentication_enabled

  # Hardware, Storage & Backup
  storage_type            = var.rds_storage_type
  allocated_storage       = var.rds_storage_size 
  max_allocated_storage   = var.rds_max_storage_size
  instance_class          = var.rds_instance_type
  storage_encrypted       = true
  skip_final_snapshot     = true
  backup_retention_period = 30
}

# ***************************************
# RDS Parameter Group
# Custom group to force SSL connections to Postgres database
# ***************************************
resource "aws_db_parameter_group" "oracle_rds_parameter_group" {
  count = var.ssl_required && var.db_engine == "postgres" ? 1 : 0
  
  name        = "oracle-rds-parameter-group"
  description = "Oracle RDS parameter group forcing SSL"
  family      = "postgres14"

  parameter {
    name  = "rds.force_ssl"
    value = 1
  }
}