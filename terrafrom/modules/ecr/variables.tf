variable "repository_name" {
  description = "Name of the ECR repository"
  type        = list(string)
  default     = ["k8s-ecr-repository-backend", "k8s-ecr-repository-frontend"]
}
