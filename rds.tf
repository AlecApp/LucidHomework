# Create master credentials for database
resource "aws_ssm_parameter" "master_username" {
  name        = "/${var.env}/database/master/user"
  description = "The master username for the RDS Cluster"
  type        = "String"
  value       = "master"
  tags = {
    environment = var.env
  }
}

# Changing the values in the keepers map will trigger the recreation of this resource. The keys/values are arbitrary.
# RDS forbids the use of /, @, ", and ' ' (blank space) in passwords. I've disabled all special characters just to avoid further unforseen incompatibilities.
resource "random_password" "master_password" {
  length  = 32
  special = false
  keepers = {
    last_updated = "06_02_21"
  }
}

# Create master password using random string. Note that the unencrypted SecureString will be stored as plaintext in .tfstate!
# (This is one more reason why we should use Terraform Cloud to store the state!)
resource "aws_ssm_parameter" "master_password" {
  name        = "/${var.env}/database/master/password"
  description = "The master password for the RDS Cluster"
  type        = "SecureString"
  value       = random_password.master_password.result
  tags = {
    environment = var.env
  }
}

# Postgres Database on Aurora Serverless
resource "aws_rds_cluster" "db" {
  cluster_identifier      = "aurora-db-postgres-${var.env}"
  engine                  = "aurora-postgresql"
  engine_mode             = "serverless"
  db_subnet_group_name    = module.vpc.database_subnet_group
  vpc_security_group_ids  = [aws_security_group.allow_rds.id]
  master_username         = aws_ssm_parameter.master_username.value
  master_password         = aws_ssm_parameter.master_password.value
  deletion_protection     = false
  skip_final_snapshot     = true
  apply_immediately       = true
  database_name           = "${var.env}-demo"
  backup_retention_period = 1
  enable_http_endpoint    = true

  scaling_configuration {
    auto_pause               = true
    max_capacity             = 4
    min_capacity             = 2
    seconds_until_auto_pause = 300
    timeout_action           = "ForceApplyCapacityChange"
  }

  tags = {
    terraform = "true"
  }
}
