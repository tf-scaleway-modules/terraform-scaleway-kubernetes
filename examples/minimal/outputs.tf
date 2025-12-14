output "cluster_id" {
  description = "ID of the Kubernetes cluster"
  value       = module.kubernetes.id
}

output "cluster_name" {
  description = "Name of the Kubernetes cluster"
  value       = module.kubernetes.name
}

output "apiserver_url" {
  description = "URL of the Kubernetes API server"
  value       = module.kubernetes.apiserver_url
}

output "kubeconfig" {
  description = "Kubeconfig for the cluster"
  value       = module.kubernetes.kubeconfig_file
  sensitive   = true
}
