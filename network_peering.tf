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

