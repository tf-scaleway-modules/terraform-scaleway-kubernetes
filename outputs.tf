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

output "type" {
  description = "Type of the Kubernetes cluster"
  value       = scaleway_k8s_cluster.this.type
}

output "cni" {
  description = "CNI plugin used by the cluster"
  value       = scaleway_k8s_cluster.this.cni
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

output "tags" {
  description = "Tags applied to the cluster"
  value       = scaleway_k8s_cluster.this.tags
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
  description = "Wildcard DNS record pointing to all cluster nodes"
  value       = scaleway_k8s_cluster.this.wildcard_dns
}

################################################################################
# Kubeconfig Outputs
################################################################################

output "kubeconfig" {
  description = "Complete kubeconfig configuration object for the cluster"
  value       = scaleway_k8s_cluster.this.kubeconfig
  sensitive   = true
}

output "kubeconfig_file" {
  description = "Raw kubeconfig file content (YAML format)"
  value       = try(scaleway_k8s_cluster.this.kubeconfig[0].config_file, null)
  sensitive   = true
}

output "kubeconfig_host" {
  description = "Kubernetes API server host from kubeconfig"
  value       = try(scaleway_k8s_cluster.this.kubeconfig[0].host, null)
}

output "kubeconfig_cluster_ca_certificate" {
  description = "Base64 encoded cluster CA certificate"
  value       = try(scaleway_k8s_cluster.this.kubeconfig[0].cluster_ca_certificate, null)
  sensitive   = true
}

output "kubeconfig_token" {
  description = "Authentication token for the cluster"
  value       = try(scaleway_k8s_cluster.this.kubeconfig[0].token, null)
  sensitive   = true
}

################################################################################
# Node Pool Outputs
################################################################################

output "node_pools" {
  description = "Map of node pool configurations and status"
  value = {
    for name, pool in scaleway_k8s_pool.this : name => {
      id           = pool.id
      name         = pool.name
      status       = pool.status
      version      = pool.version
      node_type    = pool.node_type
      size         = pool.size
      min_size     = pool.min_size
      max_size     = pool.max_size
      current_size = pool.current_size
      autoscaling  = pool.autoscaling
      autohealing  = pool.autohealing
      zone         = pool.zone
      region       = pool.region
      created_at   = pool.created_at
      updated_at   = pool.updated_at
      nodes = [
        for node in pool.nodes : {
          name        = node.name
          status      = node.status
          public_ip   = node.public_ip
          public_ipv6 = node.public_ip_v6
        }
      ]
    }
  }
}

output "node_pool_ids" {
  description = "Map of node pool names to their IDs"
  value       = { for name, pool in scaleway_k8s_pool.this : name => pool.id }
}

output "node_pool_versions" {
  description = "Map of node pool names to their Kubernetes versions"
  value       = { for name, pool in scaleway_k8s_pool.this : name => pool.version }
}

################################################################################
# Convenience Outputs for Provider Configuration
################################################################################

output "kubernetes_provider_config" {
  description = "Configuration block for the Kubernetes Terraform provider"
  value = {
    host                   = try(scaleway_k8s_cluster.this.kubeconfig[0].host, null)
    cluster_ca_certificate = try(base64decode(scaleway_k8s_cluster.this.kubeconfig[0].cluster_ca_certificate), null)
    token                  = try(scaleway_k8s_cluster.this.kubeconfig[0].token, null)
  }
  sensitive = true
}

output "helm_provider_config" {
  description = "Configuration block for the Helm Terraform provider"
  value = {
    host                   = try(scaleway_k8s_cluster.this.kubeconfig[0].host, null)
    cluster_ca_certificate = try(base64decode(scaleway_k8s_cluster.this.kubeconfig[0].cluster_ca_certificate), null)
    token                  = try(scaleway_k8s_cluster.this.kubeconfig[0].token, null)
  }
  sensitive = true
}
