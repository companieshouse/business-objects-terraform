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

  rds_ingress_from_services = {
    "bi4aud" = []
    "bi4cms" = []
  }

  default_tags = {
    Terraform = "true"
    Region    = var.aws_region
    Account   = var.aws_account
  }
}
