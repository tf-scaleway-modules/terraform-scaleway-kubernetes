################################################################################
# Cluster Outputs
################################################################################

output "id" {
  description = "ID of the Kubernetes cluster"
  value       = scaleway_k8s_cluster.this.id
}

output "name" {
  description = "Name of the Kubernetes cluster"
  value       = scaleway_k8s_cluster.this.name
}

output "status" {
  description = "Status of the Kubernetes cluster"
  value       = scaleway_k8s_cluster.this.status
}

output "version" {
  description = "Kubernetes version of the cluster"
  value       = scaleway_k8s_cluster.this.version
}

output "region" {
  description = "Region where the cluster is deployed"
  value       = scaleway_k8s_cluster.this.region
}

output "project_id" {
  description = "Scaleway project ID"
  value       = data.scaleway_account_project.this.id
}

output "organization_id" {
  description = "Scaleway organization ID"
  value       = scaleway_k8s_cluster.this.organization_id
}

output "created_at" {
  description = "Creation timestamp of the cluster"
  value       = scaleway_k8s_cluster.this.created_at
}

output "updated_at" {
  description = "Last update timestamp of the cluster"
  value       = scaleway_k8s_cluster.this.updated_at
}

################################################################################
# API Server Outputs
################################################################################

output "apiserver_url" {
  description = "URL of the Kubernetes API server"
  value       = scaleway_k8s_cluster.this.apiserver_url
}

output "wildcard_dns" {
  description = "Wildcard DNS record pointing to all nodes"
  value       = scaleway_k8s_cluster.this.wildcard_dns
}

################################################################################
# Kubeconfig Outputs
################################################################################

output "kubeconfig" {
  description = "Complete kubeconfig configuration for the cluster"
  value       = scaleway_k8s_cluster.this.kubeconfig
  sensitive   = true
}

output "kubeconfig_raw" {
  description = "Raw kubeconfig file content"
  value       = scaleway_k8s_cluster.this.kubeconfig[0].config_file
  sensitive   = true
}

output "kubeconfig_host" {
  description = "Kubernetes API server host from kubeconfig"
  value       = scaleway_k8s_cluster.this.kubeconfig[0].host
}

output "kubeconfig_cluster_ca_certificate" {
  description = "Base64 encoded cluster CA certificate"
  value       = scaleway_k8s_cluster.this.kubeconfig[0].cluster_ca_certificate
  sensitive   = true
}

output "kubeconfig_token" {
  description = "Authentication token for the cluster"
  value       = scaleway_k8s_cluster.this.kubeconfig[0].token
  sensitive   = true
}

################################################################################
# Node Pool Outputs
################################################################################

output "node_pools" {
  description = "Map of node pool details"
  value = {
    for name, pool in scaleway_k8s_pool.this : name => {
      id           = pool.id
      status       = pool.status
      current_size = pool.current_size
      version      = pool.version
      nodes        = pool.nodes
      created_at   = pool.created_at
      updated_at   = pool.updated_at
    }
  }
}

output "node_pool_ids" {
  description = "Map of node pool names to their IDs"
  value       = { for name, pool in scaleway_k8s_pool.this : name => pool.id }
}
