# Subnet group de RDS con 2 AZ privadas
resource "aws_db_subnet_group" "main" {
  name = "db-subnet-group"

  subnet_ids = [
    aws_subnet.private.id,
    aws_subnet.private_b.id,
  ]

  tags = {
    Name = "db-subnet-group"
  }
}

# Instancia RDS MySQL
resource "aws_db_instance" "main" {
  db_name           = "certeza"
  engine            = "mysql"
  engine_version    = "8.0"
  instance_class    = "db.t3.micro"
  allocated_storage = 20

  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [data.aws_security_group.db.id]

  publicly_accessible     = false
  skip_final_snapshot     = true
  deletion_protection     = false
  multi_az                = false
  backup_retention_period = 0

  tags = {
    Name = "rds-certeza"
  }
}
