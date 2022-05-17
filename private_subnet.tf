data "aws_availability_zones" "available" {}

resource "aws_subnet" "private" {
  count = 2

  availability_zone = var.legacy_subnet ? data.aws_availability_zones.available.names[count.index] : var.zones[count.index]
  cidr_block        = var.cidr_block_private_subnet[count.index]
  vpc_id            = aws_vpc.vpc.id

  tags = {
    "Name"                                          = "${var.environment_name}-private"
    "kubernetes.io/cluster/${var.environment_name}" = "shared"
    "kubernetes.io/role/internal-elb"               = "1"
    "KubespotEnvironment"                           = var.environment_name
  }
}

output "private_subnet_ids" {
  value = aws_subnet.private.*.id
}

resource "aws_eip" "eips" {
  count = var.enable_nat && length(var.eips) == 0 ? 2 : 0
  tags = {
    "KubespotEnvironment" = var.environment_name
  }
}


resource "aws_nat_gateway" "gw" {
  count = var.enable_nat ? 2 : 0

  allocation_id = length(var.eips) == 0 ? aws_eip.eips[count.index].id : var.eips[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    "Name"                = var.environment_name
    "KubespotEnvironment" = var.environment_name
  }
}

resource "aws_route_table" "private" {
  count  = 2
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name                  = "${var.environment_name}-private-${count.index}"
    "KubespotEnvironment" = var.environment_name
  }
}

output "private_route_table" {
  value = aws_route_table.private.*.id
}

resource "aws_route" "nat" {
  count = var.enable_nat ? 2 : 0

  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.gw[count.index].id
}

resource "aws_route" "ipv6" {
  count = var.enable_egress_only_internet_gateway ? 2 : 0

  route_table_id              = aws_route_table.private[count.index].id
  destination_ipv6_cidr_block = "::/0"
  egress_only_gateway_id      = aws_egress_only_internet_gateway.egress[0].id
}

resource "aws_egress_only_internet_gateway" "egress" {
  count  = var.enable_egress_only_internet_gateway ? 1 : 0
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name                  = "${var.environment_name}-egress-${count.index}"
    "KubespotEnvironment" = var.environment_name
  }
}

resource "aws_route_table_association" "private" {
  count = 2

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}
