variable "aws_region" {
  default = "ap-northeast-2"
}

variable "project" {
  default = "cloudprep"
}

variable "db_name" {
  default = "cloudprep"
}

variable "db_username" {
  default = "admin"
}

variable "db_password" {
  description = "1234"
  sensitive   = true
}

variable "my_ip" {
  description = "내 로컬 IP (SSH 접속용, x.x.x.x/32 형식)"
}
