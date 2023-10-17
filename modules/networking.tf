
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
