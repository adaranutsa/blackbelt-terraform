#############
#    VPC    #
#############
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${var.namespace}-${var.environment}-VPC"
  cidr = var.vpc_cidr

  azs             = [format("%sa", local.region), format("%sb", local.region)]
  private_subnets = [cidrsubnet(var.vpc_cidr, 8, 0), cidrsubnet(var.vpc_cidr, 8, 1)]
  public_subnets  = [cidrsubnet(var.vpc_cidr, 8, 2), cidrsubnet(var.vpc_cidr, 8, 3)]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
  enable_ipv6          = true

  tags = local.common_tags
}

#############
#    WAF    #
#############

module "regional_waf" {
  source = "trussworks/wafv2/aws"

  name  = "RegionalWAF"
  scope = "REGIONAL"

  managed_rules = [
    {
      name     = "AWSManagedRulesAmazonIpReputationList",
      priority = 0,
      "override_action" : "none",
      "excluded_rules" : []
    },
    {
      name     = "AWSManagedRulesKnownBadInputsRuleSet",
      priority = 1,
      "override_action" : "none",
      "excluded_rules" : []
    },
    {
      name     = "AWSManagedRulesCommonRuleSet",
      priority = 2,
      "override_action" : "none",
      "excluded_rules" : []
    },
    {
      name     = "AWSManagedRulesAdminProtectionRuleSet",
      priority = 3,
      "override_action" : "none",
      "excluded_rules" : []
    },
    {
      name     = "AWSManagedRulesLinuxRuleSet",
      priority = 4,
      "override_action" : "none",
      "excluded_rules" : []
    }
  ]

  tags = local.common_tags
}

#########################
#    Security Groups    #
#########################

module "external_sg_web" {
  source = "../modules/security_group"

  name   = "ExternalWebLBSG"
  vpc_id = module.vpc.vpc_id

  rules_cidr = [
    {
      from     = 80,
      to       = 80,
      protocol = "tcp",
      cidr = [
        "0.0.0.0/0"
      ]
    },
    {
      from     = 443,
      to       = 443,
      protocol = "tcp",
      cidr = [
        "0.0.0.0/0"
      ]
    }
  ]
}

module "internal_sg_web" {
  source = "../modules/security_group"

  name   = "InternalWebSG"
  vpc_id = module.vpc.vpc_id

  rules_sgsource = [
    {
      from     = 80,
      to       = 80,
      protocol = "tcp",
      sgid     = module.external_sg_web.id
    },
    {
      from     = 443,
      to       = 443,
      protocol = "tcp",
      sgid     = module.external_sg_web.id
    }
  ]
}

module "external_sg_api" {
  source = "../modules/security_group"

  name   = "ExternalApiLBSG"
  vpc_id = module.vpc.vpc_id

  rules_cidr = [
    {
      from     = 80,
      to       = 80,
      protocol = "tcp",
      cidr = [
        "0.0.0.0/0"
      ]
    },
    {
      from     = 443,
      to       = 443,
      protocol = "tcp",
      cidr = [
        "0.0.0.0/0"
      ]
    }
  ]
}

module "internal_sg_api" {
  source = "../modules/security_group"

  name   = "InternalApiSG"
  vpc_id = module.vpc.vpc_id

  rules_sgsource = [
    {
      from     = 80,
      to       = 80,
      protocol = "tcp",
      sgid     = module.external_sg_api.id
    },
    {
      from     = 443,
      to       = 443,
      protocol = "tcp",
      sgid     = module.external_sg_api.id
    }
  ]
}