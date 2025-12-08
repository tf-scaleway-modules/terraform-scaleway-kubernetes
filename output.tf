# Cluster basics
output "cluster_id" {
  description = "ID of the Scaleway Kubernetes cluster."
  value       = scaleway_k8s_cluster.cluster.id
}

output "cluster_name" {
  description = "Name of the Kubernetes cluster."
  value       = scaleway_k8s_cluster.cluster.name
}

output "cluster_region" {
  description = "Region where the Kubernetes cluster is deployed."
  value       = scaleway_k8s_cluster.cluster.region
}

output "cluster_version" {
  description = "Kubernetes version of the cluster."
  value       = scaleway_k8s_cluster.cluster.version
}

output "project_id" {
  description = "Scaleway project ID owning the cluster."
  value       = data.scaleway_account_project.project.id
}

# Kubeconfig / API
output "kubeconfig" {
  description = "Kubeconfig for the Kubernetes cluster."
  value       = scaleway_k8s_cluster.cluster.kubeconfig
  sensitive   = true
}

output "apiserver_url" {
  description = "API server URL of the Kubernetes cluster."
  value       = scaleway_k8s_cluster.cluster.apiserver_url
}
