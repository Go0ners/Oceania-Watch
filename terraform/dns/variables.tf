variable "domain_name" {
  description = "Main domain name for Route53 hosted zone"
  type        = string
  default     = "twca.cloud"
  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]\\.[a-z]{2,}$", var.domain_name))
    error_message = "Domain name must be a valid DNS domain (e.g., example.com)."
  }
}

variable "region_suffix" {
  description = "Region suffix for subdomain (e.g., oceania for oceania.twca.cloud)"
  type        = string
  default     = "oceania"
  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.region_suffix))
    error_message = "Region suffix must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "subdomains" {
  description = "List of service subdomains to create (e.g., ['grafana', 'prometheus'])"
  type        = list(string)
  default = [
    "grafana",
    "prometheus",
    "alertmanager",
    "loki",
    "traefik",
    "cadvisor"
  ]
  validation {
    condition     = alltrue([for s in var.subdomains : can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", s))])
    error_message = "Subdomains must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "instance_public_ip" {
  description = "Public IP address of the EC2 instance (from infrastructure module)"
  type        = string
  validation {
    condition     = can(regex("^(?:[0-9]{1,3}\\.){3}[0-9]{1,3}$", var.instance_public_ip))
    error_message = "Must be a valid IPv4 address."
  }
}

variable "ttl" {
  description = "TTL (Time To Live) for DNS records in seconds"
  type        = number
  default     = 300
  validation {
    condition     = var.ttl >= 60 && var.ttl <= 86400
    error_message = "TTL must be between 60 and 86400 seconds."
  }
}

variable "project_name" {
  description = "Name of the project (used in tags)"
  type        = string
  validation {
    condition     = can(regex("^[A-Za-z0-9-]+$", var.project_name))
    error_message = "Project name must contain only letters, numbers, and hyphens."
  }
}

variable "environment" {
  description = "Environment name (Dev, Staging, Qual, Prod)"
  type        = string
  validation {
    condition     = contains(["Dev", "Staging", "Qual", "Prod"], var.environment)
    error_message = "Environment must be one of: Dev, Staging, Qual, Prod"
  }
}

variable "create_zone" {
  description = "Whether to create the Route53 hosted zone (set to false if zone already exists)"
  type        = bool
  default     = false
}

variable "zone_id" {
  description = "Existing Route53 hosted zone ID (required if create_zone = false)"
  type        = string
  default     = ""
}
