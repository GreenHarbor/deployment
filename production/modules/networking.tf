
# Create a VPC
resource "aws_vpc" "default_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "greenharbor vpc"
  }
}

# Create an Internet Gateway
resource "aws_internet_gateway" "default_igw" {
  vpc_id = aws_vpc.default_vpc.id
}

# Create a Subnet
resource "aws_subnet" "default_subnet" {
  vpc_id     = aws_vpc.default_vpc.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name = "greenharbor subnet"
  }
  availability_zone = "ap-southeast-1a"
}

# Create a Subnet
resource "aws_subnet" "backup_subnet" {
  vpc_id     = aws_vpc.default_vpc.id
  cidr_block = "10.0.2.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name = "greenharbor subnet"
  }
  availability_zone = "ap-southeast-1b"
}

# Create a Route Table
resource "aws_route_table" "default_rt" {
  vpc_id = aws_vpc.default_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.default_igw.id
  }
}

# Associate the Route Table with the Subnet
resource "aws_route_table_association" "default_rta" {
  subnet_id      = aws_subnet.default_subnet.id
  route_table_id = aws_route_table.default_rt.id
}

resource "aws_api_gateway_rest_api" "api_g" {
  name        = "greenharbor-gateway"
  description = "GreenHarbor API Gateway"
}

resource "aws_api_gateway_stage" "example" {
  deployment_id = aws_api_gateway_deployment.apig-deployment.id
  rest_api_id   = aws_api_gateway_rest_api.api_g.id
  stage_name    = "prod"

  # Additional settings like logging, caching, etc. can be set here
}

resource "aws_api_gateway_method" "apig-method" {
  rest_api_id   = aws_api_gateway_rest_api.api_g.id
  resource_id   = aws_api_gateway_resource.my_resource.id
  http_method   = "GET"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.custom_authorizer.id

}

resource "aws_api_gateway_resource" "my_resource" {
  rest_api_id = aws_api_gateway_rest_api.api_g.id
  parent_id   = aws_api_gateway_rest_api.api_g.root_resource_id
  path_part   = "myresource"  # This will create a resource with path /myresource
}

resource "aws_api_gateway_integration" "example" {
  rest_api_id = aws_api_gateway_rest_api.api_g.id
  resource_id = aws_api_gateway_resource.my_resource.id
  http_method = aws_api_gateway_method.apig-method.http_method

  type        = "MOCK"
}

resource "aws_api_gateway_deployment" "apig-deployment" {
  rest_api_id = aws_api_gateway_rest_api.api_g.id


  depends_on = [
    aws_api_gateway_method.apig-method,
  ]
}

resource "aws_cognito_user_pool" "main" {
  name = "my_user_pool"

  lambda_config {
    pre_token_generation = aws_lambda_function.custom_authorizer.arn
  }
}

# Grant Cognito permission to invoke the Lambda function
resource "aws_lambda_permission" "cognito" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.custom_authorizer.function_name
  principal     = "cognito-idp.amazonaws.com"
}

resource "aws_security_group" "ecs_tasks_sg" {
  name        = "ecs_tasks_sg"
  description = "Security Group for ECS Tasks"
  vpc_id      =  aws_vpc.default_vpc.id # Replace with your VPC ID

  # Inbound rules
  ingress {
    from_port   = 0  # For HTTP traffic
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow from anywhere; adjust as needed
  }

  # Additional ingress rules can be added as needed

  # Outbound rules
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"  # Allow all protocols
    cidr_blocks = ["0.0.0.0/0"]  # Allow to anywhere
  }

  tags = {
    Name = "ecs_tasks_sg"
  }
}

resource "aws_lb" "my_alb" {
  for_each = var.ecs_tasks

  name               = each.key
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = [aws_subnet.default_subnet.id, aws_subnet.backup_subnet.id]
  
  // ... other configuration ...
}

resource "aws_lb_target_group" "my_tg" {
  for_each = var.ecs_tasks

  name     = each.key
  port     = each.value.port
  protocol = "HTTP"
  vpc_id   = aws_vpc.default_vpc.id
  target_type = "ip"

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 2
    path                = "/health"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
  }

  // ... other configuration ...
}
resource "aws_security_group" "lb_sg" {
  vpc_id = aws_vpc.default_vpc.id

   # Inbound rules
  ingress {
    from_port   = 80  # For HTTP traffic
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow from anywhere; adjust as needed
  }

  # Additional ingress rules can be added as needed

  # Outbound rules
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"  # Allow all protocols
    cidr_blocks = ["0.0.0.0/0"]  # Allow to anywhere
  }

}

resource "aws_lb_listener" "my_listener" {
  for_each = var.ecs_tasks
  load_balancer_arn = aws_lb.my_alb[each.key].arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.my_tg[each.key].arn
  }
}
