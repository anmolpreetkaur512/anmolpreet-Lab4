variable "region" {
  description = "AWS region"
  default     = "us-east-1"
}

variable "db_username" {
  description = "RDS root username"
  default     = "admin"
}

variable "db_password" {
  description = "RDS root password"
  default     = "your_secure_password"
}