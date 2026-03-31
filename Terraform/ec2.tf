# Amazon Linux 2023 최신 AMI 자동 조회
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# 키 페어
resource "aws_key_pair" "main" {
  key_name   = "${var.project}-key"
  public_key = file("~/.ssh/${var.project}-key.pub")

  tags = {
    Project = var.project
  }
}

# EC2 인스턴스
resource "aws_instance" "main" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"  # 프리티어

  key_name               = aws_key_pair.main.key_name
  vpc_security_group_ids = [aws_security_group.ec2.id]

  # 퍼블릭 IP 자동 할당
  associate_public_ip_address = true

  # 초기 설정 스크립트 (Node.js, Git, PM2 설치)
  user_data = <<-EOF
    #!/bin/bash
    # 패키지 업데이트
    yum update -y

    # Node.js 20 설치
    curl -fsSL https://rpm.nodesource.com/setup_20.x | bash -
    yum install -y nodejs

    # Git 설치
    yum install -y git

    # PM2 전역 설치
    npm install -g pm2

    # 앱 디렉토리 생성
    mkdir -p /home/ec2-user/app
    chown ec2-user:ec2-user /home/ec2-user/app
  EOF

  tags = {
    Name    = "${var.project}-server"
    Project = var.project
  }
}
