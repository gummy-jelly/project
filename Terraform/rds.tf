# RDS 서브넷 그룹
resource "aws_db_subnet_group" "main" {
  name       = "${var.project}-subnet-group"
  subnet_ids = data.aws_subnets.default.ids

  tags = {
    Name    = "${var.project}-subnet-group"
    Project = var.project
  }
}

# RDS MySQL 8.0 (프리티어)
resource "aws_db_instance" "main" {
  identifier = "${var.project}-db"

  # 엔진
  engine         = "mysql"
  engine_version = "8.0"

  # 프리티어 설정
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  storage_type      = "gp2"

  # DB 설정
  db_name  = var.db_name
  username = var.db_username
  password = var.db_password
  port     = 3306

  # 네트워크
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = true  # 로컬에서 seed.js 실행용

  # 백업 & 유지관리
  backup_retention_period = 7
  skip_final_snapshot     = true  # destroy 시 스냅샷 생략
  deletion_protection     = false

  # 프리티어 - 멀티 AZ 비활성화
  multi_az = false

  tags = {
    Name    = "${var.project}-db"
    Project = var.project
  }
}
