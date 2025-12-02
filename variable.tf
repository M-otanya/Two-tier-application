variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-2"
}

variable "my_ip" {
  description = "Your IP for SSH access"
  type        = string
  default     = "0.0.0.0/0"
}

variable "db_name" {
  description = "MySQL DB name"
  type        = string
  default     = "wordpressdb"
}

variable "db_username" {
  description = "MySQL admin user"
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "MySQL admin password"
  type        = string
  sensitive   = true
  default     = "Amking001"
}

variable "ec2_instance_type" {
  description = "EC2 type"
  type        = string
  default     = "t3.micro"
}

variable "ec2_ami_id" {
  description = "Amazon Linux 2023 AMI"
  type        = string
  default     = "ami-0fa3fe0fa7920f68e"
}
