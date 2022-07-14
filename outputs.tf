##############################################################################
# Edge Network Outputs
##############################################################################

output "vpc_id" {
  description = "ID of edge VPC"
  value       = var.vpc_id == null ? ibm_is_vpc.edge_vpc[0].id : null
}

output "network_acl" {
  description = "Network ACL name and ID"
  value       = module.network_acl.acls
}

output "subnet_zone_list" {
  description = "List of subnet ids, cidrs, names, and zones."
  value       = module.subnets.subnet_zone_list
}

##############################################################################