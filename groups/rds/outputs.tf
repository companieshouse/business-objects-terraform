output "rds_addresses" {
  value = { for dns in aws_route53_record.rds :
    dns.name => dns.fqdn
  }
}

output "busobj_rds_address" {
  value = aws_route53_record.busobj_rds.fqdn
}
