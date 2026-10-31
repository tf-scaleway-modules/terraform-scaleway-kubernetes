variable "organization_id" {
  description = "Scaleway organization ID"
  type        = string
  default     = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
}

variable "project_name" {
  description = "Name of the Scaleway project"
  type        = string
  default     = "default"
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
