resource "aws_subnet" "public" {
  count = 2

  availability_zone = var.zones[count.index]
  cidr_block        = "10.2.${count.index}.0/24"
  vpc_id            = aws_vpc.vpc.id

  tags = {
    "Name"                                          = var.environment_name
    "kubernetes.io/cluster/${var.environment_name}" = "shared"
  }
}

resource "aws_internet_gateway" "public" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = var.environment_name
  }
}

resource "aws_route_table" "public" {
  count  = 2
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.public.id
  }
  tags = {
    Name = "${var.environment_name}-public-${count.index}"
  }
}

resource "aws_route_table_association" "public" {
  count = 2

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[count.index].id
}

