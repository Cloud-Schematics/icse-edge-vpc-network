##############################################################################
# Create VPC
##############################################################################

resource "ibm_is_vpc" "edge_vpc" {
  count                       = var.vpc_id == null ? 1 : 0
  name                        = "${var.prefix}-edge-vpc"
  resource_group              = var.resource_group_id
  address_prefix_management   = "manual"
  tags                        = var.tags
  classic_access              = var.create_vpc_options.classic_access
  default_network_acl_name    = var.create_vpc_options.default_network_acl_name
  default_security_group_name = var.create_vpc_options.default_security_group_name
  default_routing_table_name  = var.create_vpc_options.default_routing_table_name
}

locals {
  vpc_id = var.vpc_id != null ? var.vpc_id : ibm_is_vpc.edge_vpc[0].id
}

##############################################################################

##############################################################################
# Create Public Gateways
##############################################################################

module "public_gateways" {
  source            = "github.com/Cloud-Schematics/vpc-public-gateway-module"
  prefix            = var.prefix
  vpc_id            = local.vpc_id
  region            = var.region
  resource_group_id = var.resource_group_id
  public_gateways = {
    for zone in [1, 2, 3] :
    "zone-${zone}" => true if(
      var.existing_public_gateways["zone-${zone}"] == null # no gateway in that zone
      && var.create_public_gateways == true                # create gateways is true
      && zone <= var.zones                                 # zone is less than or equal to total
    )
  }
}

##############################################################################

##############################################################################
# Create Address Prefixes
##############################################################################

module "address_prefixes" {
  source = "github.com/Cloud-Schematics/vpc-address-prefix-module"
  prefix = var.prefix
  region = var.region
  vpc_id = local.vpc_id
  address_prefixes = {
    for zone in [1, 2, 3] :
    "zone-${zone}" => (
      # if zone is more than total number
      zone > var.zones
      # return empty array
      ? []
      # otherwise return cidr
      : ["10.${4 + zone}.0.0/16"]
    )
  }
}

##############################################################################

##############################################################################
# Create ACL
##############################################################################

module "network_acl" {
  source       = "github.com/Cloud-Schematics/vpc-network-acl-module"
  prefix       = var.prefix
  tags         = var.tags
  vpc_id       = local.vpc_id
  network_acls = [local.edge_network_acl]
}

##############################################################################

##############################################################################
# Create Subnets
##############################################################################

module "subnets" {
  source                      = "github.com/Cloud-Schematics/vpc-subnet-module"
  prefix                      = var.prefix
  region                      = var.region
  tags                        = var.tags
  resource_group_id           = var.resource_group_id
  vpc_id                      = local.vpc_id
  use_manual_address_prefixes = true
  network_acls                = module.network_acl.acls
  public_gateways = {
    for zone in [1, 2, 3] :
    "zone-${zone}" => (
      var.existing_public_gateways["zone-${zone}"] == null
      ? module.public_gateways.gateways["zone-${zone}"]
      : var.existing_public_gateways["zone-${zone}"]
    )
  }
  subnets = {
    for zone in [1, 2, 3] :
    "zone-${zone}" => (
      zone > var.zones
      ? []
      : [
        for tier in local.create_tier_list :
        {
          name     = "edge-${tier}-zone-${zone}"
          cidr     = local.subnet_tiers["zone-${zone}"][tier]
          acl_name = "edge-acl"
          public_gateway = (
            tier != "bastion"
            ? false
            : true
          )
        } if tier != "bastion" || (tier == "bastion" && zone <= var.bastion_subnet_zones)
      ]
    )
  }
  depends_on = [module.address_prefixes] # Force dependecy on address prefixes to prevent creation errors
}

##############################################################################

##############################################################################
# Get subnets for each interface
##############################################################################

module "subnets_by_tier" {
  source           = "github.com/Cloud-Schematics/get-subnets"
  for_each         = toset(local.all_subnet_tiers)
  subnet_zone_list = module.subnets.subnet_zone_list
  regex            = each.key
}

##############################################################################