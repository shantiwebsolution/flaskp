variable "aws_access_key" {
description = "AWS Access Key ID"
type = string
sensitive = true
}

variable "aws_secret_key" {
description = "AWS Secret Access Key"
type = string
sensitive = true
}

variable "environment" {
  description = "Environment tag for resources"
  type        = string
  default     = "production"
}

variable "project_name" {
  description = "Project identifier for tagging"
  type        = string
  default     = "flaskp"
}

variable "owner" {
  description = "Owner tag for resources"
  type        = string
  default     = "user"
}

variable "instance_tags" {
  description = "Tags for EC2 instances"
  type        = map(string)
  default = {
    Name        = "web-server"
    Environment = "production"
    Project     = "flaskp"
    Owner       = "user"
  }
}

variable "log_group_name" {
  description = "Name of the CloudWatch log group"
  type        = string
  default     = "/aws/ec2/flaskp"
}

variable "log_retention_days" {
  description = "Retention period for CloudWatch log group"
  type        = number
  default     = 7
}

variable "kms_key_id" {
  description = "KMS key ID for CloudWatch log group encryption"
  type        = string
  default     = "arn:aws:kms:us-west-2:123456789012:key/abcd1234-5678-abcdefgh-9012"
}
