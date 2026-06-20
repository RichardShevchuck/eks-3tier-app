variable "cidr_block" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}


variable "environment" {
  description = "The environment for the VPC (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "availability_zones" {
  description = "The availability zones for the VPC"
  type        = list(string)
  default     = ["eu-central-1a", "eu-central-1b"]
}


variable "public_subnet_cidr" {
  description = "The CIDR block for the public subnet"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}


variable "private_subnet_cidr" {
  description = "The CIDR block for the private subnet"
  type        = list(string)
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "cluster_name" {
  type    = string
  default = "eks-3tier-app"
}
