output "busobj_rds_address" {
  value = aws_route53_record.busobj_rds.fqdn
}
