################################################################################
# Cluster Outputs
################################################################################

output "cluster_id" {
  description = "ID of the Kubernetes cluster"
  value       = module.kubernetes.id
}

output "cluster_name" {
  description = "Name of the Kubernetes cluster"
  value       = module.kubernetes.name
}

output "cluster_version" {
  description = "Kubernetes version"
  value       = module.kubernetes.version
}

output "cluster_status" {
  description = "Status of the cluster"
  value       = module.kubernetes.status
}

output "cluster_region" {
  description = "Region where the cluster is deployed"
  value       = module.kubernetes.region
}

################################################################################
# API Server Outputs
################################################################################

output "apiserver_url" {
  description = "URL of the Kubernetes API server"
  value       = module.kubernetes.apiserver_url
}

output "wildcard_dns" {
  description = "Wildcard DNS for the cluster"
  value       = module.kubernetes.wildcard_dns
}

################################################################################
# Kubeconfig Outputs
################################################################################

output "kubeconfig" {
  description = "Kubeconfig for the cluster"
  value       = module.kubernetes.kubeconfig_raw
  sensitive   = true
}

output "kubeconfig_host" {
  description = "Kubernetes API server host"
  value       = module.kubernetes.kubeconfig_host
}

################################################################################
# Node Pool Outputs
################################################################################

output "node_pools" {
  description = "Details of all node pools"
  value       = module.kubernetes.node_pools
}

output "node_pool_ids" {
  description = "Map of node pool names to IDs"
  value       = module.kubernetes.node_pool_ids
}
