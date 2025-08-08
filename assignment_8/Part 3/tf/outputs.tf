# Outputs for AWS infrastructure
output "vpc_id" {
  description = "ID of the main VPC"
  value       = aws_vpc.p3.id
}

output "public_subnet_1_id" {
  description = "ID of the first public subnet"
  value       = aws_subnet.public_subnet_1_p3.id
}

output "public_subnet_2_id" {
  description = "ID of the second public subnet"
  value       = aws_subnet.public_subnet_2_p3.id
}

output "public_subnet_3_id" {
  description = "ID of the third public subnet"
  value       = aws_subnet.public_subnet_3_p3.id
}

output "internet_gateway_id" {
  description = "ID of the internet gateway"
  value       = aws_internet_gateway.igw_p3.id
}

output "front_end_ecr_repository_arn" {
  description = "ARN of the front-end ECR repository"
  value       = aws_ecr_repository.front_end.arn
}

output "back_end_ecr_repository_arn" {
  description = "ARN of the back-end ECR repository"
  value       = aws_ecr_repository.back_end.arn
}

output "alb_dns" {
  description = "DNS name of the ALB"
  value       = aws_lb.frontend_alb.dns_name
}
