# 기본 VPC 사용
data "aws_vpc" "default" {
  default = true
}

# 기본 서브넷 목록
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# EC2 보안그룹
resource "aws_security_group" "ec2" {
  name        = "${var.project}-ec2-sg"
  description = "CloudPrep EC2 Security Group"
  vpc_id      = data.aws_vpc.default.id

  # SSH - 내 IP만
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  # 백엔드 API 포트
  ingress {
    from_port   = 4000
    to_port     = 4000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # 아웃바운드 전체 허용
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project}-ec2-sg"
    Project = var.project
  }
}

# RDS 보안그룹 - EC2에서만 접근
resource "aws_security_group" "rds" {
  name        = "${var.project}-rds-sg"
  description = "CloudPrep RDS Security Group"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2.id]
  }

  # 로컬 개발용 (내 IP에서도 접근 가능)
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project}-rds-sg"
    Project = var.project
  }
}
