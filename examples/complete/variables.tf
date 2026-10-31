variable "project_id" {
  description = "Scaleway project ID (UUID); null uses the provider default project"
  type        = string
  default     = null
}

variable "private_network_id" {
  description = "ID of the Scaleway VPC Private Network (format: region/uuid)"
  type        = string
  default     = "fr-par/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
}

variable "api_server_acl_cidrs" {
  description = "CIDRs allowed to reach the API server (include the CI/runner egress CIDR); empty creates no ACL"
  type        = list(string)
  default     = []
}

variable "workers_private_network_id" {
  description = "Private Network of the workers pool (format: region/uuid); null uses the cluster's network"
  type        = string
  default     = null
}

variable "workers_security_group_id" {
  description = "Security group of the workers pool; null keeps the Scaleway-managed group"
  type        = string
  default     = null
}
