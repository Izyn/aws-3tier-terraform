# Which subnets the database may live in (private only)
resource "aws_db_subnet_group" "db" {
  name       = "app-3tier-db-subnets"            # line 3: was "3tier-db-subnets"
  subnet_ids = aws_subnet.private[*].id
  tags       = { Name = "app-3tier-db-subnets" } # line 5: was "3tier-db-subnets"
}
resource "aws_db_instance" "db" {
  identifier = "app-3tier-db"
  engine            = "postgres"
  instance_class    = var.db_instance_class
  allocated_storage = 20
  storage_type      = "gp3"
  storage_encrypted = true

  db_name                     = "appdb"
  username                    = "appadmin"
  manage_master_user_password = true # password stored in Secrets Manager, never in code

  db_subnet_group_name   = aws_db_subnet_group.db.name
  vpc_security_group_ids = [aws_security_group.db.id]
  publicly_accessible    = false

  # Lab settings, which would be different in production:
  multi_az                = false # production: true (standby copy in a 2nd AZ)
  backup_retention_period = 0     # production: 7+ days
  skip_final_snapshot     = true  # production: false
  deletion_protection     = false # production: true
}