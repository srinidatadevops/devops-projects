output "endpoint" {
  value = aws_db_instance.postgres.endpoint
}

output "address" {
  value = aws_db_instance.postgres.address
}

output "security_group_id" {
  value = aws_security_group.postgres.id
}
