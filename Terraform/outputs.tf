output "ec2_public_ip" {
  description = "EC2 퍼블릭 IP (백엔드 주소)"
  value       = aws_instance.main.public_ip
}

output "rds_endpoint" {
  description = "RDS 엔드포인트"
  value       = aws_db_instance.main.address
}

output "s3_bucket_name" {
  description = "S3 버킷 이름 (FE 파일 업로드용)"
  value       = aws_s3_bucket.frontend.id
}

output "cloudfront_domain" {
  description = "CloudFront 도메인 (FE 접속 주소)"
  value       = aws_cloudfront_distribution.main.domain_name
}

output "ssh_command" {
  description = "EC2 SSH 접속 명령어"
  value       = "ssh -i ~/.ssh/${var.project}-key ec2-user@${aws_instance.main.public_ip}"
}
