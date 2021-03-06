##############################################################################
# Module Variables
##############################################################################

variable "prefix" {
  description = "The prefix that you would like to prepend to your resources"
  type        = string
}

variable "tags" {
  description = "List of Tags for the resource created"
  type        = list(string)
  default     = null
}

variable "resource_group_id" {
  description = "Resource group ID for the VSI"
  type        = string
  default     = null
}

variable "region" {
  description = "The region where components will be created"
  type        = string
}

##############################################################################

##############################################################################
# VPC Variables
##############################################################################

variable "vpc_id" {
  description = "ID of the VPC where VSI will be provisioned. If VPC ID is `null`, a VPC will be created automatically."
  type        = string
  default     = null
}

variable "create_vpc_options" {
  description = "Options to use when using this module to create a VPC."
  type = object({
    classic_access              = optional(bool)
    default_network_acl_name    = optional(string)
    default_security_group_name = optional(string)
    default_routing_table_name  = optional(string)
  })
  default = {
    classic_access              = false
    default_network_acl_name    = null
    default_security_group_name = null
    default_routing_table_name  = null
  }
}

variable "zones" {
  description = "Number of zones for edge VPC creation"
  type        = number
  default     = 3

  validation {
    error_message = "VPCs zones can only be 1, 2, or 3."
    condition     = var.zones > 0 && var.zones < 4
  }
}

variable "existing_public_gateways" {
  description = "Use existing public gateways for VPC id if not creating. If creating a new VPC this value will be ignored."
  type = object({
    zone-1 = string
    zone-2 = string
    zone-3 = string
  })
  default = {
    zone-1 = null
    zone-2 = null
    zone-3 = null
  }
}

variable "create_public_gateways" {
  description = "Create public gateways on the VPC. Public gateways will be created in each zone where an existing public gateway id has not been passed in using the `existing_public_gateways` variable. Public gateways will not be created in zones greater than the `zones` variable."
  type        = bool
  default     = true
}

##############################################################################

##############################################################################
# Network ACL Variables
##############################################################################

variable "add_cluster_rules" {
  description = "Automatically add needed ACL rules to allow each network to create and manage Openshift and IKS clusters."
  type        = bool
  default     = false
}

variable "global_inbound_allow_list" {
  description = "List of CIDR blocks where inbound traffic will be allowed. These allow rules will be added to each network acl."
  type        = list(string)
  default = [
    "10.0.0.0/8",   # Internal network traffic
    "161.26.0.0/16" # IBM Network traffic
  ]

  validation {
    error_message = "Global inbound allow list should contain no duplicate CIDR blocks."
    condition = length(var.global_inbound_allow_list) == 0 ? true : (
      length(var.global_inbound_allow_list) == length(distinct(var.global_inbound_allow_list))
    )
  }
}

variable "global_outbound_allow_list" {
  description = "List of CIDR blocks where outbound traffic will be allowed. These allow rules will be added to each network acl."
  type        = list(string)
  default = [
    "0.0.0.0/0"
  ]

  validation {
    error_message = "Global outbound allow list should contain no duplicate CIDR blocks."
    condition = length(var.global_outbound_allow_list) == 0 ? true : (
      length(var.global_outbound_allow_list) == length(distinct(var.global_outbound_allow_list))
    )
  }
}

variable "global_inbound_deny_list" {
  description = "List of CIDR blocks where inbound traffic will be denied. These deny rules will be added to each network acl. Deny rules will be added after all allow rules."
  type        = list(string)
  default = [
    "0.0.0.0/0"
  ]

  validation {
    error_message = "Global inbound allow list should contain no duplicate CIDR blocks."
    condition = length(var.global_inbound_deny_list) == 0 ? true : (
      length(var.global_inbound_deny_list) == length(distinct(var.global_inbound_deny_list))
    )
  }
}

variable "global_outbound_deny_list" {
  description = "List of CIDR blocks where outbound traffic will be denied. These deny rules will be added to each network acl. Deny rules will be added after all allow rules."
  type        = list(string)
  default     = []

  validation {
    error_message = "Global outbound allow list should contain no duplicate CIDR blocks."
    condition = length(var.global_outbound_deny_list) == 0 ? true : (
      length(var.global_outbound_deny_list) == length(distinct(var.global_outbound_deny_list))
    )
  }
}

##############################################################################

##############################################################################
# Subnet Variables
##############################################################################

variable "create_vpe_subnet_tier" {
  description = "Create VPE subnet tier on edge VPC."
  type        = bool
  default     = false
}

variable "create_vpn_1_subnet_tier" {
  description = "Create VPN-1 subnet tier."
  type        = bool
  default     = true
}

variable "create_vpn_2_subnet_tier" {
  description = "Create VPN-1 subnet tier."
  type        = bool
  default     = true
}

variable "bastion_subnet_zones" {
  description = "Create Bastion subnet tier for each zone in this list. Bastion subnets created cannot exceed number of zones in `var.zones`."
  type        = number
  default     = 0

  validation {
    error_message = "Bastion subnet zones can be 0, 1, 2, or 3."
    condition     = var.bastion_subnet_zones >= 0 && var.bastion_subnet_zones < 4
  }
}

##############################################################################

##############################################################################
# F5 Variables
##############################################################################

variable "vpn_firewall_type" {
  description = "F5 type. Can be `full-tunnel`, `waf`, or `vpn-and-waf`."
  type        = string

  validation {
    error_message = "Bastion type must be `full-tunnel`, `waf`, `vpn-and-waf` or `null`."
    condition     = contains(["full-tunnel", "waf", "vpn-and-waf"], var.vpn_firewall_type)
  }
}

##############################################################################