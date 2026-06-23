variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "eks-3tier-app"
}


variable "role_arn" {
  description = "ARN of the IAM role for the EKS cluster"
  type        = string
}


variable "private_subnet_ids" {
  description = "List of private subnet IDs for the EKS cluster"
  type        = list(string)
}

variable "vpc_id" {
  description = "ID of the VPC for the EKS cluster"
  type        = string
}

variable "node_role_arn" {
  description = "ARN of the IAM role for the EKS node group"
  type        = string
}
