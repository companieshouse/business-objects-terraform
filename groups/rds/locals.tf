# ------------------------------------------------------------------------
# Locals
# ------------------------------------------------------------------------
locals {
  internal_fqdn = format("%s.%s.aws.internal", split("-", var.aws_account)[1], split("-", var.aws_account)[0])

  busobj_rds_data = data.vault_generic_secret.busobj_rds.data

  busobj_rds_ingress_from_services = [
      {
        from_port                = 1521
        to_port                  = 1521
        protocol                 = "tcp"
        description              = "Business Objects Application Access"
        source_security_group_id = data.aws_security_group.busobj_app.id
      }
  ]

  default_tags = {
    Terraform = "true"
    Region    = var.aws_region
    Account   = var.aws_account
  }
}
