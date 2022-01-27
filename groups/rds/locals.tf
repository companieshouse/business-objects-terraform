# ------------------------------------------------------------------------
# Locals
# ------------------------------------------------------------------------
locals {
  admin_cidrs   = values(data.vault_generic_secret.internal_cidrs.data)
  internal_fqdn = format("%s.%s.aws.internal", split("-", var.aws_account)[1], split("-", var.aws_account)[0])

  rds_data = {
    bi4aud = data.vault_generic_secret.bi4aud_rds.data
    bi4cms = data.vault_generic_secret.bi4cms_rds.data
  }
  busobj_rds_data = data.vault_generic_secret.busobj_rds.data

  rds_ingress_from_services = {
    "bi4aud" = [
      {
        from_port                = 1521
        to_port                  = 1521
        protocol                 = "tcp"
        description              = "Business Objects Application Access"
        source_security_group_id = data.aws_security_group.busobj_app.id
      }
    ],
    "bi4cms" = [
      {
        from_port                = 1521
        to_port                  = 1521
        protocol                 = "tcp"
        description              = "Business Objects Application Access"
        source_security_group_id = data.aws_security_group.busobj_app.id
      }
    ]
  }
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
