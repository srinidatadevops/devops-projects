variable "aws_region" {
  type        = string
  description = "AWS region used for all resources."
  default     = "us-east-1"
}

variable "project_name" {
  type        = string
  description = "Short name used in AWS resource names."
  default     = "items-api"
}

variable "environment" {
  type        = string
  description = "Deployment environment name."
  default     = "prod"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR range for the application VPC."
  default     = "10.20.0.0/16"
}

variable "kubernetes_version" {
  type        = string
  description = "EKS Kubernetes version."
  default     = "1.30"
}

variable "database_name" {
  type        = string
  description = "Postgres database name."
  default     = "app_db"
}

variable "database_username" {
  type        = string
  description = "Postgres admin username."
  default     = "app_user"
}

variable "database_password" {
  type        = string
  description = "Postgres admin password supplied at plan or apply time."
  sensitive   = true
}

variable "kubernetes_namespace" {
  type        = string
  description = "Namespace used by the app workload."
  default     = "items-api"
}

variable "kubernetes_service_account" {
  type        = string
  description = "Kubernetes service account trusted by the app IAM role."
  default     = "items-api"
}
