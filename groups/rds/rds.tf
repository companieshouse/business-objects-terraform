# ------------------------------------------------------------------------------
# RDS Security Group and rules
# ------------------------------------------------------------------------------
module "rds_security_group" {
  for_each = var.rds_databases

  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 3.0"

  name        = "sgr-${each.key}-rds-001"
  description = format("Security group for the %s RDS database", upper(each.key))
  vpc_id      = data.aws_vpc.vpc.id

  ingress_cidr_blocks = concat(local.admin_cidrs)
  ingress_rules       = ["oracle-db-tcp"]
  ingress_with_cidr_blocks = [
    {
      from_port   = 5500
      to_port     = 5500
      protocol    = "tcp"
      description = "Oracle Enterprise Manager"
      cidr_blocks = join(",", concat(local.admin_cidrs))
    }
  ]
  ingress_with_source_security_group_id = local.rds_ingress_from_services[each.key]

  egress_rules = ["all-all"]
}

module "busobj_rds_security_group" {

  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 3.0"

  name        = "sgr-${var.identifier}-rds-001"
  description = "Security group for the ${var.identifier} RDS database"
  vpc_id      = data.aws_vpc.vpc.id

  ingress_cidr_blocks = local.admin_cidrs
  ingress_rules       = ["oracle-db-tcp"]
  ingress_with_cidr_blocks = [
    {
      from_port   = 5500
      to_port     = 5500
      protocol    = "tcp"
      description = "Oracle Enterprise Manager"
      cidr_blocks = join(",", local.admin_cidrs)
    }
  ]
  ingress_with_source_security_group_id = local.busobj_rds_ingress_from_services

  egress_rules = ["all-all"]
}

# ------------------------------------------------------------------------------
# RDS Instance
# ------------------------------------------------------------------------------
module "rds" {
  for_each = var.rds_databases

  source  = "terraform-aws-modules/rds/aws"
  version = "2.23.0" # Pinned version to ensure updates are a choice, can be upgraded if new features are available and required.

  create_db_parameter_group  = "true"
  create_db_subnet_group     = "true"

  character_set_name         = lookup(each.value, "character_set_name", "AL32UTF8")
  identifier                 = join("-", ["rds", each.key, var.environment, "001"])
  engine                     = lookup(each.value, "engine", "oracle-se2")
  major_engine_version       = lookup(each.value, "major_engine_version", "12.1")
  engine_version             = lookup(each.value, "engine_version", "12.1.0.2.v24")
  auto_minor_version_upgrade = lookup(each.value, "auto_minor_version_upgrade", false)
  license_model              = lookup(each.value, "license_model", "license-included")
  instance_class             = lookup(each.value, "instance_class", "db.t3.medium")
  allocated_storage          = lookup(each.value, "allocated_storage", 20)
  storage_type               = lookup(each.value, "storage_type", null)
  iops                       = lookup(each.value, "iops", null)
  multi_az                   = lookup(each.value, "multi_az", false)
  storage_encrypted          = true
  kms_key_id                 = data.aws_kms_key.rds.arn

  name                       = upper(each.key)
  username                   = local.rds_data[each.key]["admin-username"]
  password                   = local.rds_data[each.key]["admin-password"]
  port                       = "1521"

  deletion_protection        = true
  maintenance_window         = lookup(each.value, "rds_maintenance_window", "Mon:00:00-Mon:03:00")
  backup_window              = lookup(each.value, "rds_backup_window", "03:00-06:00")
  backup_retention_period    = lookup(each.value, "backup_retention_period", 7)
  skip_final_snapshot        = "false"
  final_snapshot_identifier  = "${each.key}-final-deletion-snapshot"

  # Enhanced Monitoring
  monitoring_interval             = "30"
  monitoring_role_arn             = data.aws_iam_role.rds_enhanced_monitoring.arn
  enabled_cloudwatch_logs_exports = lookup(each.value, "rds_log_exports", null)

  performance_insights_enabled          = var.environment == "live" ? true : false
  performance_insights_kms_key_id       = data.aws_kms_key.rds.arn
  performance_insights_retention_period = 7

  # RDS Security Group
  vpc_security_group_ids = flatten([
    module.rds_security_group[each.key].this_security_group_id,
    data.aws_security_group.rds_shared.id,
  ])

  # DB subnet group
  subnet_ids = data.aws_subnet_ids.data.ids

  # DB Parameter group
  family = join("-", [each.value.engine, each.value.major_engine_version])

  parameters = var.parameter_group_settings

  options = concat([
    {
      option_name                    = "OEM"
      port                           = "5500"
      vpc_security_group_memberships = [module.rds_security_group[each.key].this_security_group_id]
    },
    {
      option_name = "JVM"
    },
    {
      option_name = "SQLT"
      version     = "2018-07-25.v1"
      option_settings = [
        {
          name  = "LICENSE_PACK"
          value = "N"
        },
      ]
    },
  ], each.value.per_instance_options)

  timeouts = {
    "create" : "80m",
    "delete" : "80m",
    "update" : "80m"
  }

  tags = merge(
    local.default_tags,
    map(
      "ServiceTeam", format("%s-DBA-Support", upper(each.key))
    )
  )
}

module "busobj_rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "2.23.0"

  create_db_parameter_group = true
  create_db_subnet_group    = true

  character_set_name         = var.character_set_name
  identifier                 = "rds-${var.identifier}-${var.environment}-001"
  engine                     = "oracle-se2"
  major_engine_version       = var.major_engine_version
  engine_version             = var.engine_version
  auto_minor_version_upgrade = var.auto_minor_version_upgrade
  license_model              = var.license_model
  instance_class             = var.instance_class
  allocated_storage          = var.allocated_storage
  storage_type               = var.storage_type
  iops                       = var.iops
  multi_az                   = var.multi_az
  storage_encrypted          = true
  kms_key_id                 = data.aws_kms_key.rds.arn

  name     = upper(var.name)
  username = local.busobj_rds_data["admin-username"]
  password = local.busobj_rds_data["admin-password"]
  port     = "1521"

  deletion_protection       = true
  maintenance_window        = var.rds_maintenance_window
  backup_window             = var.rds_backup_window
  backup_retention_period   = var.backup_retention_period
  skip_final_snapshot       = false
  final_snapshot_identifier = "${var.identifier}-final-deletion-snapshot"

  # Enhanced Monitoring
  monitoring_interval             = "30"
  monitoring_role_arn             = data.aws_iam_role.rds_enhanced_monitoring.arn
  enabled_cloudwatch_logs_exports = var.rds_log_exports

  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_kms_key_id       = data.aws_kms_key.rds.arn
  performance_insights_retention_period = 7

  # RDS Security Group
  vpc_security_group_ids = [
    module.busobj_rds_security_group.this_security_group_id,
    data.aws_security_group.rds_shared.id
  ]

  # DB subnet group
  subnet_ids = data.aws_subnet_ids.data.ids

  # DB Parameter group
  family = "oracle-se2-${var.major_engine_version}"

  parameters = var.parameter_group_settings

  options = [
    {
      option_name                    = "OEM"
      port                           = "5500"
      vpc_security_group_memberships = [module.busobj_rds_security_group.this_security_group_id]
    },
    {
      option_name = "JVM"
    },
    {
      option_name = "SQLT"
      version     = "2018-07-25.v1"
      option_settings = [
        {
          name  = "LICENSE_PACK"
          value = "N"
        },
      ]
    },
    {
      option_name = "Timezone"
      option_settings = [
        {
          name  = "TIME_ZONE"
          value = "Europe/London"
        },
      ]
    }
  ]

  timeouts = {
    "create" : "80m",
    "delete" : "80m",
    "update" : "80m"
  }

  tags = merge(
    local.default_tags,
    map(
      "ServiceTeam", "${upper(var.identifier)}-DBA-Support"
    )
  )
}