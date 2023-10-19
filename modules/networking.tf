
# Create a VPC
resource "aws_vpc" "default-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "greenharbor vpc"
  }
}

# Create an Internet Gateway
resource "aws_internet_gateway" "default_igw" {
  vpc_id = aws_vpc.default-vpc.id
}

# Create a Subnet
resource "aws_subnet" "default_subnet" {
  vpc_id     = aws_vpc.default_vpc.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name = "greenharbor subnet"
  }
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

# Create an Application Load Balancer
resource "aws_lb" "main" {
  name               = "my-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = [aws_subnet.main.id]
}

resource "aws_security_group" "lb_sg" {
  vpc_id = aws_vpc.main.id
  # ... ingress/egress rules ...
}

resource "aws_api_gateway_method" "apig-method" {
  rest_api_id   = aws_api_gateway_rest_api.my_api.id
  resource_id   = aws_api_gateway_resource.my_resource.id
  http_method   = "GET"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.custom_authorizer.id

}

resource "aws_api_gateway_deployment" "apig-deployment" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id


  depends_on = [
    aws_api_gateway_method.apig-method,
  ]
}

resource "aws_cognito_user_pool" "main" {
  name = "my_user_pool"

  lambda_config {
    pre_token_generation = aws_lambda_function.jwt_verifier.arn
  }
}

# Grant Cognito permission to invoke the Lambda function
resource "aws_lambda_permission" "cognito" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.jwt_verifier.function_name
  principal     = "cognito-idp.amazonaws.com"
}
