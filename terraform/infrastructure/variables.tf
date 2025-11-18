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
