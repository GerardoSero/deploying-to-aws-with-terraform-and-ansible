resource "aws_vpc" "vpc_main_oregon" {
  provider             = aws.worker_region
  cidr_block           = "192.168.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "worker-vpc-jenkins"
  }
}

resource "aws_internet_gateway" "igw_oregon" {
  provider = aws.worker_region
  vpc_id   = aws_vpc.vpc_main_oregon.id
}

resource "aws_subnet" "subnet_1_oregon" {
  provider   = aws.worker_region
  vpc_id     = aws_vpc.vpc_main_oregon.id
  cidr_block = "192.168.1.0/24"
}

resource "aws_route_table" "internet_route_oregon" {
  provider = aws.worker_region
  vpc_id   = aws_vpc.vpc_main_oregon.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_oregon.id
  }
  route {
    cidr_block                = "10.0.1.0/24"
    vpc_peering_connection_id = aws_vpc_peering_connection.useast1_uswest2.id
  }
  lifecycle {
    ignore_changes = all
  }
  tags = {
    Name = "Worker-Region-RT"
  }
}

resource "aws_main_route_table_association" "set_worker_default_rt_assoc" {
  provider       = aws.worker_region
  vpc_id         = aws_vpc.vpc_main_oregon.id
  route_table_id = aws_route_table.internet_route_oregon.id
}

# Create security group for allowing TCP/22 from you IP in us-west-2
resource "aws_security_group" "jenkins_sg_oregon" {
  provider    = aws.worker_region
  name        = "jenkins_sg_oregon"
  description = "Allow TCP/8080 & TCP/22"
  vpc_id      = aws_vpc.vpc_main_oregon.id
  ingress {
    description = "Allow 22 from our public IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.external_ip]
  }
  ingress {
    description = "Allow traffic from us-east-1"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.1.0/24"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
