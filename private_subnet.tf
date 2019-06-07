resource "aws_subnet" "private" {
  count = 2

  availability_zone = "${var.zones[count.index]}"
  cidr_block        = "10.2.${count.index+2}.0/24"
  vpc_id            = "${aws_vpc.vpc.id}"

  tags = "${
    map(
     "Name", "${var.cluster-name}-private",
     "kubernetes.io/cluster/${var.cluster-name}", "shared",
     "kubernetes.io/role/internal-elb", "1",
    )
  }"
}

resource "aws_nat_gateway" "gw" {
  count = 2

  allocation_id = "${var.eips[count.index]}"
  subnet_id     = "${aws_subnet.public.*.id[count.index]}"
}

resource "aws_route_table" "private" {
  count  = 2
  vpc_id = "${aws_vpc.vpc.id}"

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.gw.*.id[count.index]}"
  }

  route {
    cidr_block                = "172.60.0.0/16"
    vpc_peering_connection_id = "${aws_vpc_peering_connection.env_to_rds.id}"
  }

  tags {
    Name = "k8s-private-${count.index}"
  }
}

resource "aws_route_table_association" "private" {
  count = 2

  subnet_id      = "${aws_subnet.private.*.id[count.index]}"
  route_table_id = "${aws_route_table.private.*.id[count.index]}"
}
