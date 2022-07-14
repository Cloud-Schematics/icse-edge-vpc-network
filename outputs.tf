output network_acl {
    description = "Network ACL name and ID"
    value       = module.network_acl.acls
}

output subnet_zone_list {
    description = "List of subnet ids, cidrs, names, and zones."
    value       = module.subnets.subnet_zone_list
}