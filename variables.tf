# -------------------- PROJECT VARIABLES ------------------ #
variable "project_name" {
  type        = string
  description = "The name of the Project"
  default     = "default"
}
variable "organization_id" {
  type        = string
  description = "The unique identifier of the Organization with which the Project is associated."

}

# -------------------- PRIVATE NETWORK ID ------------------ #
## This will be passed as dependency
variable "private_network_id" {
  description = "ID of the Scaleway VPC Private Network (format: <region>/<uuid>)"
  type        = string
}

# -------------------- CLUSTER VARIABLES ------------------ #

variable "cluster_name" {
  type        = string
  description = "The name for the Kubernetes cluster."

}

variable "cluster_type" {
  type        = string
  description = "type of Kubernetes cluster"
  default     = null


}

variable "cluster_description" {
  type        = string
  description = "A description for the Kubernetes cluster."
  default     = null


}

variable "cluster_version" {
  type        = string
  description = "The version of the Kubernetes cluster."

}

variable "cluster_cni" {
  type        = string
  description = "The Container Network Interface (CNI) for the Kubernetes cluster."

}

variable "cluster_tags" {
  type        = list(string)
  description = "The tags associated with the Kubernetes cluster"
  default     = null

}

variable "delete_additional_resources" {
  sensitive   = true
  type        = bool
  description = "Delete additional resources like block volumes and loadbalancers that were created in Kubernetes on cluster deletion"
  default     = false

}

variable "cluster_feature_gates" {
  type        = list(string)
  description = "The list of feature gates to enable on the cluster."
  default     = null


}

variable "cluster_admission_plugins" {
  type        = list(string)
  description = "The list of admission plugins to enable on the cluster."
  default     = null

}

variable "cluster_apiserver_cert_sans" {
  type        = list(string)
  description = "Additional Subject Alternative Names for the Kubernetes API server certificate."
  default     = null

}

variable "cluster_region" {
  type        = string
  description = "(Defaults to provider region) The region in which the cluster should be created."
  default     = null


}

variable "enable_auto_upgrade" {
  type        = bool
  description = "Set to true to enable Kubernetes patch version auto upgrades. ~> Important: When enabling auto upgrades, the version field take a minor version like x.y (ie 1.18)."
  default     = false
}

variable "maintenance_window_start_hour" {
  type        = string
  description = "The start hour (UTC) of the 2-hour auto upgrade maintenance window (0 to 23)."
  default     = 3

}

variable "maintenance_window_day" {
  type        = string
  description = "The day of the auto upgrade maintenance window (monday to sunday, or any)."
  default     = "sunday"

}

variable "enable_autoscaler" {
  type        = bool
  description = "To enable cluster autoscaler"
  default     = false
}

variable "disable_scale_down" {
  type        = bool
  description = "Disables the scale down feature of the autoscaler."
  default     = false
}

variable "scale_down_delay_after_add" {
  type        = string
  description = "How long after scale up that scale down evaluation resumes."
  default     = "10m"


}

variable "scale_down_unneeded_time" {
  type        = string
  description = "How long a node should be unneeded before it is eligible for scale down."
  default     = "10m"

}

variable "estimator" {
  type        = string
  description = "Type of resource estimator to be used in scale up."
  default     = "binpacking"

}

variable "expander" {
  type        = string
  description = "Type of node group expander to be used in scale up."
  default     = "random"

}

variable "ignore_daemonsets_utilization" {
  type        = bool
  description = "Ignore DaemonSet pods when calculating resource utilization for scaling down."
  default     = false
}

variable "balance_similar_node_groups" {
  type        = bool
  description = "Detect similar node groups and balance the number of nodes between them."
  default     = false
}

variable "expendable_pods_priority_cutoff" {
  type        = number
  description = "Pods with priority below cutoff will be expendable. They can be killed without any consideration during scale down and they don't cause scale up. Pods with null priority (PodPriority disabled) are non expendable."
  default     = -10
}

variable "scale_down_utilization_threshold" {
  type        = number
  description = "Node utilization level, defined as sum of requested resources divided by capacity, below which a node can be considered for scale down."
  default     = 0.5
}

variable "max_graceful_termination_sec" {
  type        = number
  description = "Maximum number of seconds the cluster autoscaler waits for pod termination when trying to scale down a node."
  default     = 600
}

#######################################################################
# Node pools

variable "node_pools" {
  description = "Node pools configuration for Kubernetes cluster."
  type = map(object({
    node_type           = string
    size                = number
    min_size            = number
    max_size            = number
    autoscaling         = bool
    autohealing         = bool
    wait_for_pool_ready = bool
    tags                = list(string)
  }))
  default = {}
}