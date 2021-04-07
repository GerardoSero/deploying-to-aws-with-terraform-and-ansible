resource "aws_vpc" "vpc_main" {
  provider             = aws.region_main
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "main-vpc-jenkins"
  }
}

resource "aws_internet_gateway" "igw" {
  provider = aws.region_main
  vpc_id   = aws_vpc.vpc_main.id
}

data "aws_availability_zones" "azs" {
  provider = aws.region_main
  state    = "available"
}

resource "aws_subnet" "subnet_1" {
  provider          = aws.region_main
  availability_zone = element(data.aws_availability_zones.azs.names, 0)
  vpc_id            = aws_vpc.vpc_main.id
  cidr_block        = "10.0.1.0/24"
}

resource "aws_subnet" "subnet_2" {
  provider          = aws.region_main
  availability_zone = element(data.aws_availability_zones.azs.names, 1)
  vpc_id            = aws_vpc.vpc_main.id
  cidr_block        = "10.0.2.0/24"
}

resource "aws_route_table" "internet_route" {
  provider = aws.region_main
  vpc_id   = aws_vpc.vpc_main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  route {
    cidr_block                = "192.168.1.0/24"
    vpc_peering_connection_id = aws_vpc_peering_connection.useast1_uswest2.id
  }
  lifecycle {
    ignore_changes = all
  }
  tags = {
    Name = "Master-Region-RT"
  }
}

resource "aws_main_route_table_association" "set_master_default_rt_assoc" {
  provider = aws.region_main
  vpc_id   = aws_vpc.vpc_main.id

  route_table_id = aws_route_table.internet_route.id
}

# Create security group for allowing TCP/8080 from * and TCP/22 from you IP in us-east-1
resource "aws_security_group" "jenkins_sg" {
  provider    = aws.region_main
  name        = "jenkins_sg"
  description = "Allow TCP/8080 & TCP/22"
  vpc_id      = aws_vpc.vpc_main.id
  ingress {
    description = "Allow 22 from our public IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.external_ip]
  }
  ingress {
    description     = "Allow anyone on port 8080"
    from_port       = var.webserver_port
    to_port         = var.webserver_port
    protocol        = "tcp"
    security_groups = [aws_security_group.lb_sg.id]
  }
  ingress {
    description = "Allow traffic from us-west-2"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["192.168.1.0/24"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
