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


data "aws_availability_zones" "available" {
  state = "available"
}

# Create VPC with DNS settings
resource "aws_vpc" "p3" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "main-vpc-p3"
    Environment = "production"

    Owner = "user"
  }
}

# Create public subnets in different AZs
resource "aws_subnet" "public_subnet_1_p3" {
  vpc_id                  = aws_vpc.p3.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[0]

  tags = {
    Name        = "public-subnet-1-p3"
    Environment = "production"

    Owner = "user"
  }
}

resource "aws_subnet" "public_subnet_2_p3" {
  vpc_id                  = aws_vpc.p3.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[1]

  tags = {
    Name        = "public-subnet-2-p3"
    Environment = "production"

    Owner = "user"
  }
}

resource "aws_subnet" "public_subnet_3_p3" {
  vpc_id                  = aws_vpc.p3.id
  cidr_block              = "10.0.3.0/24"
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[2]

  tags = {
    Name        = "public-subnet-3-p3"
    Environment = "production"

    Owner = "user"
  }
}

# Create internet gateway
resource "aws_internet_gateway" "igw_p3" {
  vpc_id = aws_vpc.p3.id

  tags = {
    Name        = "main-igw-p3"
    Environment = "production"

    Owner = "user"
  }
}

# Create route tables
resource "aws_route_table" "public_route_table_p3" {
  vpc_id = aws_vpc.p3.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_p3.id
  }

  tags = {
    Name        = "public-route-table-p3"
    Environment = "production"

    Owner = "user"
  }
}

# Associate public subnets with the public route table so they become truly public
resource "aws_route_table_association" "public_subnet_1_assoc_p3" {
  subnet_id      = aws_subnet.public_subnet_1_p3.id
  route_table_id = aws_route_table.public_route_table_p3.id
}

resource "aws_route_table_association" "public_subnet_2_assoc_p3" {
  subnet_id      = aws_subnet.public_subnet_2_p3.id
  route_table_id = aws_route_table.public_route_table_p3.id
}

resource "aws_route_table_association" "public_subnet_3_assoc_p3" {
  subnet_id      = aws_subnet.public_subnet_3_p3.id
  route_table_id = aws_route_table.public_route_table_p3.id
}

# Create ECR repositories
resource "aws_ecr_repository" "front_end" {
  name = "front-end"
}

resource "aws_ecr_repository" "back_end" {
  name = "back-end"
}

# Create ECS cluster
resource "aws_ecs_cluster" "terraform" {
  name = "Terraform"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

# Create ECS capacity provider for Fargate
resource "aws_ecs_cluster_capacity_providers" "terraform" {
  cluster_name = aws_ecs_cluster.terraform.name

  capacity_providers = ["FARGATE"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}

# Create IAM role for ECS task execution
resource "aws_iam_role" "ecs_exec" {
  name = "ecsTaskExecutionRolep3"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_exec" {
  role       = aws_iam_role.ecs_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
resource "aws_cloudwatch_log_group" "backend_lg_p3" {
  name              = "/ecs/backend-p3"
  retention_in_days = 14
}
resource "aws_cloudwatch_log_group" "frontend_lg_p3" {
  name              = "/ecs/front-p3"
  retention_in_days = 14
}

# ECS task definition for frontend
resource "aws_ecs_task_definition" "frontend_task" {
  family                   = "frontend-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_exec.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  container_definitions = jsonencode([
    {
      name      = "front-end",
      image     = "417447013917.dkr.ecr.ap-south-1.amazonaws.com/front-end:latest",
      essential = true,
      portMappings = [
        {
          containerPort = 3000,
          hostPort      = 3000,
          protocol      = "tcp"
        }
      ],
      environment = [
        {
          name  = "BACKEND_URL",
          value = "http://${aws_lb.backend_alb.dns_name}/"
        }
      ],
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = "/ecs/front-p3",
          awslogs-region        = "ap-south-1",
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])

  tags = {
    Name        = "frontend-task"
    Environment = "production"
    Owner       = "user"
  }
}

# ECS task definition for backend
resource "aws_ecs_task_definition" "backend_task" {
  family                   = "backend-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_exec.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  container_definitions = jsonencode([
    {
      name      = "back-end",
      image     = "417447013917.dkr.ecr.ap-south-1.amazonaws.com/back-end:latest",
      essential = true,
      portMappings = [
        {
          containerPort = 5000,
          hostPort      = 5000,
          protocol      = "tcp"
        }
      ],
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = "/ecs/backend-p3",
          awslogs-region        = "ap-south-1",
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])

  tags = {
    Name        = "backend-task"
    Environment = "production"
    Owner       = "user"
  }
}

# Security group for ALB
resource "aws_security_group" "alb_sg" {
  name        = "alb-sg-p3"
  description = "Security group for ALB"
  vpc_id      = aws_vpc.p3.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
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
    Name        = "alb-sg-p3"
    Environment = "production"
    Owner       = "user"
  }
}

# Security group for ECS tasks
resource "aws_security_group" "ecs_sg" {
  name        = "ecs-sg-p3"
  description = "Security group for ECS tasks"
  vpc_id      = aws_vpc.p3.id

  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  ingress {
    from_port       = 5000
    to_port         = 5000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "ecs-sg-p3"
    Environment = "production"
    Owner       = "user"
  }
}

# Application Load Balancer
resource "aws_lb" "frontend_alb" {
  name               = "frontend-alb-p3"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_subnet_1_p3.id, aws_subnet.public_subnet_2_p3.id, aws_subnet.public_subnet_3_p3.id]

  enable_deletion_protection = false

  tags = {
    Name        = "frontend-alb-p3"
    Environment = "production"
    Owner       = "user"
  }
}
resource "aws_lb" "backend_alb" {
  name               = "backend-alb-p3"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_subnet_1_p3.id, aws_subnet.public_subnet_2_p3.id, aws_subnet.public_subnet_3_p3.id]

  enable_deletion_protection = false

  tags = {
    Name        = "backend-alb-p3"
    Environment = "production"
    Owner       = "user"
  }
}

# Target Group for frontend
resource "aws_lb_target_group" "frontend_tg" {
  name        = "frontend-tg-p3"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.p3.id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name        = "frontend-tg-p3"
    Environment = "production"
    Owner       = "user"
  }
}

# Target Group for backend
resource "aws_lb_target_group" "backend_tg" {
  name        = "backend-tg-p3"
  port        = 5000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.p3.id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name        = "backend-tg-p3"
    Environment = "production"
    Owner       = "user"
  }
}

# ALB Listener
resource "aws_lb_listener" "frontend_listener" {
  load_balancer_arn = aws_lb.frontend_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend_tg.arn
  }
}
# ALB Listener
resource "aws_lb_listener" "backend_listener" {
  load_balancer_arn = aws_lb.backend_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_tg.arn
  }
}



# ECS Service for frontend
resource "aws_ecs_service" "frontend_service" {
  name            = "frontend-service"
  cluster         = aws_ecs_cluster.terraform.id
  task_definition = aws_ecs_task_definition.frontend_task.arn
  desired_count   = 1

  network_configuration {
    subnets          = [aws_subnet.public_subnet_1_p3.id, aws_subnet.public_subnet_2_p3.id, aws_subnet.public_subnet_3_p3.id]
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.frontend_tg.arn
    container_name   = "front-end"
    container_port   = 3000
  }

  capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 100
  }

  depends_on = [aws_lb_listener.backend_listener]

  tags = {
    Name        = "frontend-service"
    Environment = "production"
    Owner       = "user"
  }
}

# ECS Service for backend
resource "aws_ecs_service" "backend_service" {
  name            = "backend-service"
  cluster         = aws_ecs_cluster.terraform.id
  task_definition = aws_ecs_task_definition.backend_task.arn
  desired_count   = 1

  network_configuration {
    subnets          = [aws_subnet.public_subnet_1_p3.id, aws_subnet.public_subnet_2_p3.id, aws_subnet.public_subnet_3_p3.id]
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.backend_tg.arn
    container_name   = "back-end"
    container_port   = 5000
  }

  capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 100
  }

  depends_on = [aws_lb_listener.backend_listener]

  tags = {
    Name        = "backend-service"
    Environment = "production"
    Owner       = "user"
  }
}
