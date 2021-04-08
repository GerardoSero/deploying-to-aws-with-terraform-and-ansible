resource "aws_vpc" "vpc_main" {
  provider             = aws.main_region
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "main-vpc-jenkins"
  }
}

data "aws_availability_zones" "azs" {
  provider = aws.main_region
  state    = "available"
}

resource "aws_subnet" "subnet_1" {
  provider          = aws.main_region
  availability_zone = element(data.aws_availability_zones.azs.names, 0)
  vpc_id            = aws_vpc.vpc_main.id
  cidr_block        = "10.0.1.0/24"
}

resource "aws_subnet" "subnet_2" {
  provider          = aws.main_region
  availability_zone = element(data.aws_availability_zones.azs.names, 1)
  vpc_id            = aws_vpc.vpc_main.id
  cidr_block        = "10.0.2.0/24"
}

resource "aws_internet_gateway" "vpc_main_igw" {
  provider = aws.main_region
  vpc_id   = aws_vpc.vpc_main.id
}

resource "aws_route_table" "vpc_main_rt" {
  provider = aws.main_region
  vpc_id   = aws_vpc.vpc_main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.vpc_main_igw.id
  }
  route {
    cidr_block                = "192.168.1.0/24"
    vpc_peering_connection_id = aws_vpc_peering_connection.useast1_uswest2.id
  }
  tags = {
    Name = "Master-Region-RT"
  }
}

resource "aws_main_route_table_association" "set_master_default_rt_assoc" {
  provider = aws.main_region
  vpc_id   = aws_vpc.vpc_main.id

  route_table_id = aws_route_table.vpc_main_rt.id
}

# Create security group for allowing TCP/8080 from * and TCP/22 from you IP in us-east-1
resource "aws_security_group" "jenkins_sg" {
  provider    = aws.main_region
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
