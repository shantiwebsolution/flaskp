# Terraform configuration for AWS EC2 infrastructure
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region     = "ap-south-1"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

# Data sources for AMI and availability zones
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

# Create VPC with DNS settings
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "main-vpc"
    Environment = "production"
    
    Owner       = "user"
  }
}

# Create public subnets in different AZs
resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[0]

  tags = {
    Name        = "public-subnet-1"
    Environment = "production"
    
    Owner       = "user"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[1]

  tags = {
    Name        = "public-subnet-2"
    Environment = "production"
    
    Owner       = "user"
  }
}

# Create internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "main-igw"
    Environment = "production"
    
    Owner       = "user"
  }
}

# Create route tables
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name        = "public-route-table"
    Environment = "production"
    
    Owner       = "user"
  }
}

# Associate public subnets with the public route table so they become truly public
resource "aws_route_table_association" "public_subnet_1_assoc" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_subnet_2_assoc" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_route_table.id
}


# Create security group
resource "aws_security_group" "frontend_app_sg" {
  name        = "frontend-app-sg"
  description = "Allow SSH, HTTP, HTTPS traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Frontend Access"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }



  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name        = "frontend-app-sg"
    Environment = "production"
    
    Owner       = "user"
  }
}
resource "aws_security_group" "backend_app_sg" {
  name        = "backend-app-sg"
  description = "Allow SSH, HTTP, HTTPS traffic"
  vpc_id      = aws_vpc.main.id


  ingress {
    description     = "Backend access from frontend only"
    from_port       = 5000
    to_port         = 5000
    protocol        = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
 
  tags = {
    Name        = "backend-app-sg"
    Environment = "production"
    
    Owner       = "user"
  }
}
resource "aws_instance" "backend_app" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.public_subnet_2.id
  vpc_security_group_ids      = [aws_security_group.backend_app_sg.id]
  associate_public_ip_address = true
  user_data                   = filebase64("be_server_userdata.sh")
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name

  tags = {
    Name        = "backend-server"
    Environment = "production"
    
    Owner       = "user"
  }

  depends_on = []
}
resource "aws_instance" "frontend_app" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.public_subnet_2.id
  vpc_security_group_ids      = [aws_security_group.frontend_app_sg.id]
  associate_public_ip_address = true
  user_data                   =  base64encode(templatefile("fe_server_userdata.tpl", {
    be_server_public_ip  = aws_instance.backend_app.public_ip    
  }))
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name

  tags = {
    Name        = "frontend-server"
    Environment = "production"
    
    Owner       = "user"
  }

}



# Create IAM role for CloudWatch
resource "aws_iam_role" "ec2_role" {
  name = "ec2-cloudwatch-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ec2.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "ec2-cloudwatch-role"
    Environment = "production"
    
    Owner       = "user"
  }
}

# Attach IAM role to instances
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-cloudwatch-profile"
  role = aws_iam_role.ec2_role.name
}

# Attach managed policies required for SSM and CloudWatch agent
resource "aws_iam_role_policy_attachment" "ssm_attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "cw_attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Create CloudWatch log group
resource "aws_cloudwatch_log_group" "log_group" {
  name              = "/aws/ec2/"
  retention_in_days = 7

  tags = {
    Name        = "-log-group"
    Environment = "production"
    
    Owner       = "user"
  }
}


