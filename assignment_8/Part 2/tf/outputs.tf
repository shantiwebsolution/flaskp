# Outputs for AWS EC2 infrastructure
output "vpc_id" {
  description = "ID of the main VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_1_id" {
  description = "ID of the first public subnet"
  value       = aws_subnet.public_subnet_1.id
}

output "public_subnet_2_id" {
  description = "ID of the second public subnet"
  value       = aws_subnet.public_subnet_2.id
}

output "internet_gateway_id" {
  description = "ID of the internet gateway"
  value       = aws_internet_gateway.igw.id
}



output "backend_security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.backend_app_sg.id
}
output "frontend_security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.backend_app_sg.id
}

output "instance_ids" {
  description = "List of EC2 instance IDs"
  value       = [aws_instance.backend_app.id,aws_instance.frontend_app.id]
}


output "private_ip_addresses" {
  description = "Private IP addresses of the instances"
  value       = [aws_instance.backend_app.private_ip, aws_instance.frontend_app.private_ip]
}

output "iam_role_arn" {
  description = "ARN of the EC2 IAM role"
  value       = aws_iam_role.ec2_role.arn
}

output "iam_instance_profile_arn" {
  description = "ARN of the EC2 instance profile"
  value       = aws_iam_instance_profile.ec2_profile.arn
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.log_group.name
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.log_group.arn
}
