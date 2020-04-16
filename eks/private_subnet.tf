data "aws_availability_zones" "available" {}

resource "aws_subnet" "private" {
  count = 2

  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = "10.2.${count.index + 2}.0/24"
  vpc_id            = aws_vpc.vpc.id

  tags = {
    "Name"                                          = "${var.environment_name}-private"
    "kubernetes.io/cluster/${var.environment_name}" = "shared"
    "kubernetes.io/role/internal-elb"               = "1"
  }
}

resource "aws_eip" "eips" {
  count = length(var.eips) == 0 ? 2 : 0
}


resource "aws_nat_gateway" "gw" {
  count = var.nat_enabled ? 2 : 0

  allocation_id = length(var.eips) == 0 ? aws_eip.eips[count.index].id : var.eips[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
}

resource "aws_route_table" "private" {
  count = var.nat_enabled ? 2 : 0
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.gw[count.index].id
  }

  tags = {
    Name = "k8s-private-${count.index}"
  }
}

resource "aws_egress_only_internet_gateway" "egress_ipv6" {
  count = var.enable_egress_only_internet_gateway ? 2 : 0
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "main"
  }
}

resource "aws_route_table_association" "private" {
  count = 2

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

