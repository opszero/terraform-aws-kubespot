resource "aws_vpc_peering_connection" "env_to_rds" {
  vpc_id        = "${aws_vpc.vpc.id}"
  peer_owner_id = "355934147401"
  peer_vpc_id   = "${var.db_vpc_id}"
  auto_accept   = true

  accepter {
    allow_remote_vpc_dns_resolution = true
  }

  requester {
    allow_remote_vpc_dns_resolution = true
  }

  tags {
    Name = "${var.vpc_peer_name}"
  }
}

resource "aws_route" "rtb-ef308a89" {
  route_table_id            = "rtb-ef308a89"
  destination_cidr_block    = "${aws_vpc.vpc.cidr_block}"
  vpc_peering_connection_id = "${aws_vpc_peering_connection.env_to_rds.id}"
}

resource "aws_route" "rtb-63358f05" {
  route_table_id            = "rtb-63358f05"
  destination_cidr_block    = "${aws_vpc.vpc.cidr_block}"
  vpc_peering_connection_id = "${aws_vpc_peering_connection.env_to_rds.id}"
}

resource "aws_route" "rtb-88308aee" {
  route_table_id            = "rtb-88308aee"
  destination_cidr_block    = "${aws_vpc.vpc.cidr_block}"
  vpc_peering_connection_id = "${aws_vpc_peering_connection.env_to_rds.id}"
}

resource "aws_route" "rtb-58378d3e" {
  route_table_id            = "rtb-58378d3e"
  destination_cidr_block    = "${aws_vpc.vpc.cidr_block}"
  vpc_peering_connection_id = "${aws_vpc_peering_connection.env_to_rds.id}"
}

resource "aws_route" "rtb-ec308a8a" {
  route_table_id            = "rtb-ec308a8a"
  destination_cidr_block    = "${aws_vpc.vpc.cidr_block}"
  vpc_peering_connection_id = "${aws_vpc_peering_connection.env_to_rds.id}"
}

resource "aws_security_group_rule" "database_allow_postgres_prod" {
  type              = "ingress"
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
  cidr_blocks       = ["${aws_vpc.vpc.cidr_block}"]
  security_group_id = "sg-d80d72a3"
}

resource "aws_security_group_rule" "database_allow_redis" {
  type              = "ingress"
  from_port         = 0
  to_port           = -1
  protocol          = "all"
  cidr_blocks       = ["${aws_vpc.vpc.cidr_block}"]
  security_group_id = "sg-d80d72a3"
}
