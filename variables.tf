################################################################################
# Project Configuration
################################################################################

variable "organization_id" {
  description = "Scaleway organization ID"
  type        = string

  validation {
    condition     = can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.organization_id))
    error_message = "Organization ID must be a valid UUID."
  }
}

variable "project_name" {
  description = "Name of the Scaleway project"
  type        = string
  default     = "default"
}

################################################################################
# Cluster Configuration
################################################################################

variable "name" {
  description = "Name of the Kubernetes cluster"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,62}$", var.name))
    error_message = "Cluster name must start with a letter, contain only lowercase letters, numbers, and hyphens, and be at most 63 characters."
  }
}

variable "description" {
  description = "Description for the Kubernetes cluster"
  type        = string
  default     = null
}

variable "type" {
  description = "Type of Kubernetes cluster"
  type        = string
  default     = "kapsule"

  validation {
    condition = contains([
      "kapsule",
      "multicloud",
      "kapsule-dedicated-4",
      "kapsule-dedicated-8",
      "kapsule-dedicated-16",
      "multicloud-dedicated-4",
      "multicloud-dedicated-8",
      "multicloud-dedicated-16"
    ], var.type)
    error_message = "Cluster type must be one of: kapsule, multicloud, kapsule-dedicated-4/8/16, multicloud-dedicated-4/8/16."
  }
}

variable "kubernetes_version" {
  description = "Kubernetes version for the cluster (e.g., '1.31' for auto-upgrade or '1.31.0' for fixed version)"
  type        = string

  validation {
    condition     = can(regex("^\\d+\\.\\d+(\\.\\d+)?$", var.kubernetes_version))
    error_message = "Kubernetes version must be in format 'X.Y' (for auto-upgrade) or 'X.Y.Z' (fixed version)."
  }
}

variable "cni" {
  description = "Container Network Interface plugin"
  type        = string
  default     = "cilium"

  validation {
    condition     = contains(["cilium", "calico", "weave", "flannel", "none"], var.cni)
    error_message = "CNI must be one of: cilium, calico, weave, flannel, none."
  }
}

variable "tags" {
  description = "Tags to apply to the Kubernetes cluster"
  type        = list(string)
  default     = []
}

variable "region" {
  description = "Scaleway region for the cluster (defaults to provider region)"
  type        = string
  default     = null

  validation {
    condition     = var.region == null || contains(["fr-par", "nl-ams", "pl-waw"], var.region)
    error_message = "Region must be one of: fr-par, nl-ams, pl-waw."
  }
}

################################################################################
# Network Configuration
################################################################################

variable "private_network_id" {
  description = "ID of the Scaleway VPC Private Network (format: region/uuid)"
  type        = string

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]{3}/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.private_network_id))
    error_message = "Private network ID must be in format 'region/uuid' (e.g., 'fr-par/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx')."
  }
}

################################################################################
# Cluster Features
################################################################################

variable "delete_additional_resources" {
  description = "Delete additional resources (block volumes, loadbalancers) on cluster deletion"
  type        = bool
  default     = false
}

variable "feature_gates" {
  description = "List of Kubernetes feature gates to enable on the cluster"
  type        = list(string)
  default     = []
}

variable "admission_plugins" {
  description = "List of Kubernetes admission plugins to enable on the cluster"
  type        = list(string)
  default     = []
}

variable "apiserver_cert_sans" {
  description = "Additional Subject Alternative Names for the API server certificate"
  type        = list(string)
  default     = []
}

################################################################################
# Auto Upgrade Configuration
################################################################################

variable "auto_upgrade" {
  description = "Auto upgrade configuration for the cluster. When enabled, kubernetes_version must be a minor version (e.g., '1.31')."
  type = object({
    enabled                       = optional(bool, false)
    maintenance_window_start_hour = optional(number, 3)
    maintenance_window_day        = optional(string, "sunday")
  })
  default = {}

  validation {
    condition     = var.auto_upgrade.maintenance_window_start_hour >= 0 && var.auto_upgrade.maintenance_window_start_hour <= 23
    error_message = "Maintenance window start hour must be between 0 and 23."
  }

  validation {
    condition     = contains(["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday", "any"], var.auto_upgrade.maintenance_window_day)
    error_message = "Maintenance window day must be one of: monday, tuesday, wednesday, thursday, friday, saturday, sunday, any."
  }
}

################################################################################
# Autoscaler Configuration
################################################################################

variable "autoscaler_config" {
  description = "Cluster autoscaler configuration. Set to null to disable the autoscaler."
  type = object({
    disable_scale_down               = optional(bool, false)
    scale_down_delay_after_add       = optional(string, "10m")
    scale_down_unneeded_time         = optional(string, "10m")
    estimator                        = optional(string, "binpacking")
    expander                         = optional(string, "random")
    ignore_daemonsets_utilization    = optional(bool, false)
    balance_similar_node_groups      = optional(bool, false)
    expendable_pods_priority_cutoff  = optional(number, -10)
    scale_down_utilization_threshold = optional(number, 0.5)
    max_graceful_termination_sec     = optional(number, 600)
  })
  default = null

  validation {
    condition     = var.autoscaler_config == null || contains(["binpacking", "random"], var.autoscaler_config.estimator)
    error_message = "Estimator must be one of: binpacking, random."
  }

  validation {
    condition     = var.autoscaler_config == null || contains(["random", "most-pods", "least-waste", "priority", "price"], var.autoscaler_config.expander)
    error_message = "Expander must be one of: random, most-pods, least-waste, priority, price."
  }

  validation {
    condition     = var.autoscaler_config == null || (var.autoscaler_config.scale_down_utilization_threshold >= 0 && var.autoscaler_config.scale_down_utilization_threshold <= 1)
    error_message = "Scale down utilization threshold must be between 0 and 1."
  }
}

################################################################################
# OpenID Connect Configuration
################################################################################

variable "oidc_config" {
  description = "OpenID Connect configuration for the cluster API server"
  type = object({
    issuer_url      = string
    client_id       = string
    username_claim  = optional(string)
    username_prefix = optional(string)
    groups_claim    = optional(list(string))
    groups_prefix   = optional(string)
    required_claim  = optional(list(string))
  })
  default = null

  validation {
    condition     = var.oidc_config == null || can(regex("^https://", var.oidc_config.issuer_url))
    error_message = "OIDC issuer URL must start with 'https://'."
  }
}

################################################################################
# Node Pools Configuration
################################################################################

variable "node_pools" {
  description = "Map of node pool configurations. The map key is used as the pool name."
  type = map(object({
    # Required
    node_type = string
    size      = number

    # Scaling
    min_size    = optional(number)
    max_size    = optional(number)
    autoscaling = optional(bool, false)
    autohealing = optional(bool, true)

    # Runtime
    container_runtime = optional(string, "containerd")
    kubelet_args      = optional(map(string), {})

    # Placement
    placement_group_id = optional(string)
    zone               = optional(string)
    region             = optional(string)

    # Storage
    root_volume_type       = optional(string)
    root_volume_size_in_gb = optional(number)

    # Network
    public_ip_disabled = optional(bool, false)

    # Metadata
    tags = optional(list(string), [])

    # Lifecycle
    wait_for_pool_ready = optional(bool, true)
    upgrade_policy = optional(object({
      max_unavailable = optional(number, 1)
      max_surge       = optional(number, 0)
    }))
  }))
  default = {}

  validation {
    condition     = length(var.node_pools) > 0
    error_message = "At least one node pool must be defined."
  }

  validation {
    condition = alltrue([
      for k, v in var.node_pools : can(regex("^[a-z][a-z0-9-]{0,62}$", k))
    ])
    error_message = "Node pool names must start with a letter, contain only lowercase letters, numbers, and hyphens, and be at most 63 characters."
  }

  validation {
    condition = alltrue([
      for k, v in var.node_pools : v.size >= 0
    ])
    error_message = "Node pool size must be non-negative."
  }

  validation {
    condition = alltrue([
      for k, v in var.node_pools : v.min_size == null || v.min_size >= 0
    ])
    error_message = "Node pool min_size must be non-negative."
  }

  validation {
    condition = alltrue([
      for k, v in var.node_pools : v.max_size == null || v.max_size >= 1
    ])
    error_message = "Node pool max_size must be at least 1."
  }

  validation {
    condition = alltrue([
      for k, v in var.node_pools : v.min_size == null || v.max_size == null || v.min_size <= v.max_size
    ])
    error_message = "Node pool min_size must be less than or equal to max_size."
  }

  validation {
    condition = alltrue([
      for k, v in var.node_pools : contains(["containerd", "crio"], v.container_runtime)
    ])
    error_message = "Container runtime must be one of: containerd, crio."
  }

  validation {
    condition = alltrue([
      for k, v in var.node_pools : v.root_volume_type == null || contains(["l_ssd", "b_ssd"], v.root_volume_type)
    ])
    error_message = "Root volume type must be one of: l_ssd, b_ssd."
  }

  validation {
    condition = alltrue([
      for k, v in var.node_pools : v.root_volume_size_in_gb == null || v.root_volume_size_in_gb >= 20
    ])
    error_message = "Root volume size must be at least 20 GB."
  }

  validation {
    condition = alltrue([
      for k, v in var.node_pools : v.zone == null || can(regex("^[a-z]{2}-[a-z]{3}-[1-3]$", v.zone))
    ])
    error_message = "Zone must be in format 'region-az' (e.g., 'fr-par-1', 'nl-ams-2')."
  }
}
