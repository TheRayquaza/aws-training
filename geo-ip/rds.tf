resource "aws_db_instance" "stats_db" {
  allocated_storage    = 20
  engine               = "postgres"
  db_name              = "geoipstats"
  instance_class       = "db.t3.micro"
  username             = "myusername"
  password             = "yoursecurepassword"
  skip_final_snapshot  = true
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.stats_db_subnet.name  
  multi_az             = false
}

resource "aws_db_subnet_group" "stats_db_subnet" {
  name       = "db-subnet-group"
  subnet_ids = [aws_subnet.main.id, aws_subnet.backup.id] 

  tags = {
    Name = "My DB Subnet Group"
  }
}

resource "aws_security_group" "db_sg" {
  name        = "db_sg"
  description = "Security group for RDS PostgreSQL"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
    security_groups = [aws_security_group.lambda_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.main.cidr_block]
    security_groups = [aws_security_group.lambda_sg.id]
  }
  
}

output "rds_endpoint" {
  value = aws_db_instance.stats_db.address
}
