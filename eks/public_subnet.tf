resource "aws_subnet" "public" {
  count = 2

  availability_zone = var.zones[count.index]
  cidr_block        = var.cidr_block_public_subnet[count.index]
  vpc_id            = aws_vpc.vpc.id

  tags = {
    "Name"                                          = var.environment_name
    "kubernetes.io/cluster/${var.environment_name}" = "shared"
    "kubernetes.io/role/elb"                        = "1"
    "KubespotEnvironment"                           = var.environment_name
  }
}

output "public_subnet_ids" {
  value = aws_subnet.public.*.id
}

resource "aws_internet_gateway" "public" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    "Name"                = var.environment_name
    "KubespotEnvironment" = var.environment_name
  }
}

resource "aws_route" "ig" {
  count          = 2
  route_table_id = aws_route_table.public[count.index].id

  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.public.id
}

resource "aws_route_table" "public" {
  count  = 2
  vpc_id = aws_vpc.vpc.id

  tags = {
    "Name"                = "${var.environment_name}-public-${count.index}"
    "KubespotEnvironment" = var.environment_name
  }
}

resource "aws_route_table_association" "public" {
  count = 2

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[count.index].id
}

output "public_route_table" {
  value = aws_route_table.public.*.id
}
