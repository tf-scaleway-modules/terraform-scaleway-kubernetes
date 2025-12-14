################################################################################
# Project Configuration
################################################################################

variable "project_name" {
  description = "Name of the Scaleway project"
  type        = string
  default     = "default"
}

variable "organization_id" {
  description = "Scaleway organization ID"
  type        = string
}

################################################################################
# Cluster Configuration
################################################################################

variable "name" {
  description = "Name of the Kubernetes cluster"
  type        = string
}

variable "description" {
  description = "Description for the Kubernetes cluster"
  type        = string
  default     = null
}

variable "type" {
  description = "Type of Kubernetes cluster (kapsule, multicloud)"
  type        = string
  default     = "kapsule"

  validation {
    condition     = var.type == null || contains(["kapsule", "multicloud", "kapsule-dedicated-8", "kapsule-dedicated-16"], var.type)
    error_message = "Cluster type must be one of: kapsule, multicloud, kapsule-dedicated-8, kapsule-dedicated-16."
  }
}

variable "kubernetes_version" {
  description = "Kubernetes version for the cluster (e.g., '1.31')"
  type        = string
}

variable "cni" {
  description = "Container Network Interface plugin (cilium, calico, weave, flannel, none)"
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
}

variable "private_network_id" {
  description = "ID of the Scaleway VPC Private Network (format: region/uuid)"
  type        = string
}

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
  description = "Auto upgrade configuration for the cluster"
  type = object({
    enabled                       = bool
    maintenance_window_start_hour = number
    maintenance_window_day        = string
  })
  default = {
    enabled                       = false
    maintenance_window_start_hour = 3
    maintenance_window_day        = "sunday"
  }

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
  description = "Cluster autoscaler configuration. Set to null to disable autoscaler."
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
# Node Pools Configuration
################################################################################

variable "node_pools" {
  description = "Map of node pool configurations"
  type = map(object({
    node_type              = string
    size                   = number
    min_size               = optional(number)
    max_size               = optional(number)
    autoscaling            = optional(bool, false)
    autohealing            = optional(bool, true)
    container_runtime      = optional(string, "containerd")
    tags                   = optional(list(string), [])
    placement_group_id     = optional(string)
    zone                   = optional(string)
    root_volume_type       = optional(string)
    root_volume_size_in_gb = optional(number)
    wait_for_pool_ready    = optional(bool, true)
    upgrade_policy = optional(object({
      max_unavailable = optional(number, 1)
      max_surge       = optional(number, 0)
    }))
  }))
  default = {}

  validation {
    condition     = alltrue([for k, v in var.node_pools : v.container_runtime == null || contains(["containerd", "crio", "docker"], v.container_runtime)])
    error_message = "Container runtime must be one of: containerd, crio, docker."
  }

  validation {
    condition     = alltrue([for k, v in var.node_pools : v.root_volume_type == null || contains(["l_ssd", "b_ssd"], v.root_volume_type)])
    error_message = "Root volume type must be one of: l_ssd, b_ssd."
  }
}
