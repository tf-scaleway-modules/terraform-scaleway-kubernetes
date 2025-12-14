variable "organization_id" {
  description = "Scaleway organization ID"
  type        = string
}

variable "project_name" {
  description = "Name of the Scaleway project"
  type        = string
  default     = "default"
}

variable "private_network_id" {
  description = "ID of the Scaleway VPC Private Network"
  type        = string
}
