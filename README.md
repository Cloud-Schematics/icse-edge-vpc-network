# Edge VPC Network Module

Create an Edge VPC network on a new or existing VPC. This network is set up to allow users to deploy F5 Big IP instances.

![network](.docs/network.png)

---

## Table of Contents

1. [Edge VPC](#edge-vpc)
2. [Address Prefixes](#address-prefixes)
3. [Network ACL](#network-acl)
    - [Default Allow Rules](#default-allow-rules)
    - [Default Deny Rules](#default-deny-rules)
4. [Subnets](#subnets)
5. [Module Variables](#module-variables)

---

## Edge VPC

Using this module users can create a new edge VPC or provision network components on an existing VPC.

- To use an existing VPC, set the `vpc_id` variable to the existing VPC ID. 
- To create a new edge VPC, set the `vpc_id` variable to `null`.

---

## Address Prefixes

VPCs have a quota of a total of 25 prefixes. To ensure that all subnet tiers can be provisioned, the following CIDR prefixes are added to the VPC. Prefixes are only created for the number of zones specified in the [zone variable](./variables.tf#L55). This module uses the [ICSE VPC Address Prefix module](github.com/Cloud-Schematics/vpc-address-prefix-module) to create prefixes.

### Prefixes by Zone

Zone | Prefix
-----|--------
1    | 10.5.0.0/16
2    | 10.6.0.0/16
3    | 10.7.0.0/16

---

## Network ACL

This module creates a single ACL where all subnets will be attached. This module uses the [ICSE VPC Network ACL Module](https://github.com/Cloud-Schematics/vpc-network-acl-module) to create the access control list. Allow rules for this network ACL is managed by the following variables:

Name                                | Type         | Description                                                                                                                                                                                  | Sensitive | Default
----------------------------------- | ------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------- | ---------------------------------
add_cluster_rules                   | bool         | Automatically add needed ACL rules to allow each network to create and manage Openshift and IKS clusters.                                                                                    |           | true
global_inbound_allow_list           | list(string) | List of CIDR blocks where inbound traffic will be allowed. These allow rules will be added to each network acl.                                                                              |           | [ "10.0.0.0/8", "161.26.0.0/16" ]
global_outbound_allow_list          | list(string) | List of CIDR blocks where outbound traffic will be allowed. These allow rules will be added to each network acl.                                                                             |           | [ "0.0.0.0/0" ]
global_inbound_deny_list            | list(string) | List of CIDR blocks where inbound traffic will be denied. These deny rules will be added to each network acl. Deny rules will be added after all allow rules.                                |           | [ "0.0.0.0/0" ]
global_outbound_deny_list           | list(string) | List of CIDR blocks where outbound traffic will be denied. These deny rules will be added to each network acl. Deny rules will be added after all allow rules.                               |           | []

### Default Allow Rules

Name                                                     | CIDR            | Direction
---------------------------------------------------------|-----------------|----------
Allow all internal VPC network traffic                   | `10.0.0.0/8`    | Inbound
Allow inbound traffic from IBM private service endpoints | `161.26.0.0/16` | Inbound
Allow all outbound traffic                               | `0.0.0.0/0`     | Outbound

### Default Deny Rules

Name                                                     | CIDR            | Direction
---------------------------------------------------------|-----------------|----------
All not-allowed traffic                                  | `0.0.0.0/0`     | Inbound

### Additional Allow Rules

- If the pattern uses the `f5-external` subnet tier, a rule is created to allow incoming traffic to port 443
- If the pattern uses the `bastion` subnet tier, a rule is created to allow incoming traffic with the source port 443

---

## Subnets

This template creates subnets based on the number of zones in your VPC and the network configuration pattern from the [vpn_firewall_type variable](./variables.tf#L173). Supported patterns are `full-tunnel`, `waf`, and `vpn-and-waf`.

Name          | Zone 1 CIDR Block | Zone 2 CIDR Block | Zone 3 CIDR Block | WAF   | Full Tunnel   | VPN and WAF   | Variable
--------------| ------------------|-------------------|-------------------|:-----:|:-------------:|:-------------:| ---------
vpn-1         | 10.5.10.0/24      | 10.6.10.0/24      | 10.7.10.0/24      | ✅    | ✅             | ✅            | `create_vpn_1_subnet_tier`
vpn-2         | 10.5.20.0/24      | 10.6.20.0/24      | 10.7.20.0/24      | ✅    | ✅             | ✅            | `create_vpn_2_subnet_tier`
f5-management | 10.5.30.0/24      | 10.6.30.0/24      | 10.7.30.0/24      | ✅    | ✅             | ✅            | n/a
f5-external   | 10.5.40.0/24      | 10.6.40.0/24      | 10.7.40.0/24      | ✅    | ✅             | ✅            | n/a
f5-workload   | 10.5.50.0/24      | 10.6.50.0/24      | 10.7.50.0/24      | ✅    | ❌             | ✅            | n/a
f5-bastion    | 10.5.60.0/24      | 10.6.60.0/24      | 10.7.60.0/24      | ❌    | ✅             | ✅            | n/a
bastion       | 10.5.70.0/24      | 10.6.70.0/24      | 10.7.70.0/24      | ✅    | ✅             | ✅            | `bastion_subnet_zones`
vpe           | 10.5.80.0/24      | 10.6.80.0/24      | 10.7.80.0/24      | ✅    | ✅             | ✅            | `create_vpe_subnet_tier`

---

## Module Variables

Name                       | Type                                                                                                                                                                                 | Description                                                                                                                                                    | Sensitive | Default
-------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------- | -------------------------------------------------------------------------------------------------------------------------------
prefix                     | string                                                                                                                                                                               | The prefix that you would like to prepend to your resources                                                                                                    |           | 
tags                       | list(string)                                                                                                                                                                         | List of Tags for the resource created                                                                                                                          |           | null
resource_group_id          | string                                                                                                                                                                               | Resource group ID for the VSI                                                                                                                                  |           | null
region                     | string                                                                                                                                                                               | The region where components will be created                                                                                                                    |           | 
vpc_id                     | string                                                                                                                                                                               | ID of the VPC where VSI will be provisioned. If VPC ID is `null`, a VPC will be created automatically.                                                         |           | null
create_vpc_options         | object({ classic_access = optional(bool) default_network_acl_name = optional(string) default_security_group_name = optional(string) default_routing_table_name = optional(string) }) | Options to use when using this module to create a VPC.                                                                                                         |           | { classic_access = false default_network_acl_name = null default_security_group_name = null default_routing_table_name = null }
zones                      | number                                                                                                                                                                               | Number of zones for edge VPC creation                                                                                                                          |           | 3
add_cluster_rules          | bool                                                                                                                                                                                 | Automatically add needed ACL rules to allow each network to create and manage Openshift and IKS clusters.                                                      |           | false
global_inbound_allow_list  | list(string)                                                                                                                                                                         | List of CIDR blocks where inbound traffic will be allowed. These allow rules will be added to each network acl.                                                |           | [ "10.0.0.0/8", "161.26.0.0/16" ]
global_outbound_allow_list | list(string)                                                                                                                                                                         | List of CIDR blocks where outbound traffic will be allowed. These allow rules will be added to each network acl.                                               |           | [ "0.0.0.0/0" ]
global_inbound_deny_list   | list(string)                                                                                                                                                                         | List of CIDR blocks where inbound traffic will be denied. These deny rules will be added to each network acl. Deny rules will be added after all allow rules.  |           | [ "0.0.0.0/0" ]
global_outbound_deny_list  | list(string)                                                                                                                                                                         | List of CIDR blocks where outbound traffic will be denied. These deny rules will be added to each network acl. Deny rules will be added after all allow rules. |           | []
create_vpe_subnet_tier     | bool                                                                                                                                                                                 | Create VPE subnet tier on edge VPC.                                                                                                                            |           | false
create_vpn_1_subnet_tier   | bool                                                                                                                                                                                 | Create VPN-1 subnet tier.                                                                                                                                      |           | true
create_vpn_2_subnet_tier   | bool                                                                                                                                                                                 | Create VPN-1 subnet tier.                                                                                                                                      |           | true
bastion_subnet_zones       | number                                                                                                                                                                               | Create Bastion subnet tier for each zone in this list. Bastion subnets created cannot exceed number of zones in `var.zones`.                                   |           | 0
vpn_firewall_type          | string                                                                                                                                                                               | F5 type. Can be `full-tunnel`, `waf`, or `vpn-and-waf`.

---

## Module Outputs

Name             | Description
---------------- | --------------------------------------------
vpc_id           | ID for edge VPC
network_acl      | Network ACL name and ID
subnet_zone_list | List of subnet ids, cidrs, names, and zones.