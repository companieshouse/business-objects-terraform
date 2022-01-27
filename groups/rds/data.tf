data "aws_vpc" "vpc" {
  tags = {
    Name = "vpc-${var.aws_account}"
  }
}

data "aws_subnet_ids" "data" {
  vpc_id = data.aws_vpc.vpc.id
  filter {
    name   = "tag:Name"
    values = ["sub-data-*"]
  }
}

data "aws_security_group" "rds_shared" {
  filter {
    name   = "group-name"
    values = ["sgr-rds-shared-001*"]
  }
}

data "aws_security_group" "busobj_app" {
  filter {
    name   = "group-name"
    values = ["sgr-windows-workloads-bus-obj-*"]
  }
}

data "aws_route53_zone" "private_zone" {
  name         = local.internal_fqdn
  private_zone = true
}

data "aws_iam_role" "rds_enhanced_monitoring" {
  name = "irol-rds-enhanced-monitoring"
}

data "aws_kms_key" "rds" {
  key_id = "alias/kms-rds"
}

data "vault_generic_secret" "bi4aud_rds" {
  path = "applications/${var.aws_profile}/bi4aud/rds"
}

data "vault_generic_secret" "bi4cms_rds" {
  path = "applications/${var.aws_profile}/bi4cms/rds"
}

data "vault_generic_secret" "busobj_rds" {
  path = "applications/${var.aws_profile}/bibusobj/rds"
}

data "vault_generic_secret" "internal_cidrs" {
  path = "aws-accounts/network/internal_cidr_ranges"
}
