resource "aws_vpc" "vpc_main" {
  provider             = aws.region_main
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "main-vpc-jenkins"
  }
}

resource "aws_vpc" "vpc_main_oregon" {
  provider             = aws.region_worker
  cidr_block           = "192.168.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "worker-vpc-jenkins"
  }
}

resource "aws_internet_gateway" "igw" {
  provider = aws.region_main
  vpc_id   = aws_vpc.vpc_main.id
}

resource "aws_internet_gateway" "igw_oregon" {
  provider = aws.region_worker
  vpc_id   = aws_vpc.vpc_main_oregon.id
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

resource "aws_subnet" "subnet_1_oregon" {
  provider   = aws.region_worker
  vpc_id     = aws_vpc.vpc_main_oregon.id
  cidr_block = "192.168.1.0/24"
}

resource "aws_vpc_peering_connection" "useast1_uswest2" {
  provider    = aws.region_main
  vpc_id      = aws_vpc.vpc_main.id
  peer_region = var.region_worker
  peer_vpc_id = aws_vpc.vpc_main_oregon.id
}

resource "aws_vpc_peering_connection_accepter" "accept_peering" {
  provider                  = aws.region_worker
  vpc_peering_connection_id = aws_vpc_peering_connection.useast1_uswest2.id
  auto_accept               = true
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

resource "aws_route_table" "internet_route_oregon" {
  provider = aws.region_worker
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
  provider       = aws.region_worker
  vpc_id         = aws_vpc.vpc_main_oregon.id
  route_table_id = aws_route_table.internet_route_oregon.id
}
