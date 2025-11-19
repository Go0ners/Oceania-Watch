variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name of the project (must match step 1)"
  type        = string
  validation {
    condition     = can(regex("^[A-Za-z0-9-]+$", var.project_name))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, qual, prod)"
  type        = string
  validation {
    condition     = contains(["Dev", "Staging", "Qual", "Prod"], var.environment)
    error_message = "Environment must be one of: Dev, Staging, Qual, Prod"
  }
}

variable "allowed_ssh_ips" {
  description = "List of IP addresses allowed to SSH to the instance"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.large"
}

variable "root_volume_size" {
  description = "Size of the root EBS volume in GB"
  type        = number
  default     = 100
}

variable "root_volume_type" {
  description = "Type of EBS volume"
  type        = string
  default     = "gp3"
}

variable "enable_public_ip" {
  description = "Enable public IP for the instance"
  type        = bool
  default     = true
}

variable "enable_detailed_monitoring" {
  description = "Enable detailed CloudWatch monitoring"
  type        = bool
  default     = false
}

variable "enable_termination_protection" {
  description = "Enable termination protection"
  type        = bool
  default     = false
}

variable "ssh_key_directory" {
  description = "Directory to store SSH keys"
  type        = string
  default     = "~/.ssh/oceania"
}

# DNS Module Variables
variable "enable_dns_module" {
  description = "Enable DNS module (Route53)"
  type        = bool
  default     = false
}

variable "dns_domain_name" {
  description = "Main domain name for Route53 hosted zone"
  type        = string
  default     = "twca.cloud"
}

variable "dns_region_suffix" {
  description = "Region suffix for subdomain (e.g., oceania)"
  type        = string
  default     = "oceania"
}

variable "dns_subdomains" {
  description = "List of service subdomains to create"
  type        = list(string)
  default = [
    "grafana",
    "prometheus",
    "alertmanager",
    "loki",
    "traefik",
    "cadvisor"
  ]
}

variable "dns_create_zone" {
  description = "Whether to create the Route53 hosted zone"
  type        = bool
  default     = false
}

variable "dns_zone_id" {
  description = "Existing Route53 hosted zone ID (required if dns_create_zone = false)"
  type        = string
  default     = ""
}

variable "dns_ttl" {
  description = "TTL for DNS records in seconds"
  type        = number
  default     = 300
}
