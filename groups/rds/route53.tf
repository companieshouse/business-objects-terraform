resource "aws_route53_record" "rds" {
  for_each = { for key, database in var.rds_databases : key => database }

  zone_id = data.aws_route53_zone.private_zone.zone_id
  name    = format("%s%s", each.key, "db")
  type    = "CNAME"
  ttl     = "300"
  records = [module.rds[each.key].this_db_instance_address]
}

resource "aws_route53_record" "busobj_rds" {
  zone_id = data.aws_route53_zone.private_zone.zone_id
  name    = "${var.name}db"
  type    = "CNAME"
  ttl     = "300"
  records = [module.busobj_rds.this_db_instance_address]
}