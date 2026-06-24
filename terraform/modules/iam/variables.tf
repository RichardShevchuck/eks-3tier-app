variable "cluster_name" {
  description = "The name of the EKS cluster"
  type        = string
  default     = "eks-3tier-app"
}

variable "github_repo" {
  description = "GitHub repo in format owner/repo"
  type        = string
  default     = "RichardShevchuck/eks-3tier-app"
}

