output "ec2_public_ip" {
  description = "Public IP of the Web Server"
  value       = aws_instance.web.public_ip
}

output "rds_endpoint" {
  description = "RDS endpoint"
  value       = aws_db_instance.mysql.endpoint
}

output "ssh_command" {
  description = "SSH command to connect"
  value       = "ssh -i \"C:/Users/ADMN/Documents/AWS Projects/terraform-generated-key.pem\" ec2-user@${aws_instance.web.public_ip}"
}
