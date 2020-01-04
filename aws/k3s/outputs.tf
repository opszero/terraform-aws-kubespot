output "public-ip" {
  value = aws_instance.cluster.public_ip
}