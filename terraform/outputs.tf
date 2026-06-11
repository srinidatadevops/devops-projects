output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "ecr_repository_url" {
  value = module.ecr.repository_url
}

output "app_bucket_name" {
  value = module.app_bucket.bucket_name
}

output "rds_endpoint" {
  value     = module.rds.endpoint
  sensitive = true
}

output "app_pod_role_arn" {
  value = module.iam.role_arn
}

output "kubeconfig_command" {
  value = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}
