output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "cluster_name" {
  value = module.eks.cluster_name
}

output "oidc_issuer_url" {
  value = module.eks.oidc_issuer_url
}

output "ecr_repository_url" {
  value = module.ecr.repository_url[*]
}
