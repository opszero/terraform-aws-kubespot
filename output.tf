output "public_subnet_ids" {
  value = aws_subnet.public.*.id
}

output "public_route_table" {
  value = aws_route_table.public.*.id
}

# from private_subnet.tf

output "private_subnet_ids" {
  value = aws_subnet.private.*.id
}

output "private_route_table" {
  value = aws_route_table.private.*.id
}

output "nat_gateway_ids" {
  value = aws_nat_gateway.gw.*.id
}
