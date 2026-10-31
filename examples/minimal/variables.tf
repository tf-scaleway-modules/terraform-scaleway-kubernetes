variable "project_id" {
  description = "Scaleway project ID (UUID); null uses the provider default project"
  type        = string
  default     = null
}

variable "private_network_id" {
  description = "ID of the Scaleway VPC Private Network (format: region/uuid)"
  type        = string
}
