output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.main.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_eip.main.public_ip
}

output "instance_private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = aws_instance.main.private_ip
}

output "instance_public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = aws_eip.main.public_dns
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.ec2.id
}

output "key_pair_name" {
  description = "Name of the AWS key pair"
  value       = aws_key_pair.main.key_name
}

output "private_key_path" {
  description = "Path to the private SSH key"
  value       = local_file.private_key.filename
}

output "public_key_path" {
  description = "Path to the public SSH key"
  value       = local_file.public_key.filename
}

output "ssh_connection_string" {
  description = "SSH connection command"
  value       = "ssh -i ${local_file.private_key.filename} ec2-user@${aws_eip.main.public_ip}"
}

output "ssh_user" {
  description = "Default SSH user for Amazon Linux"
  value       = "ec2-user"
}

output "ami_id" {
  description = "AMI ID used for the instance"
  value       = data.aws_ami.amazon_linux_2023.id
}

output "ami_name" {
  description = "AMI name used for the instance"
  value       = data.aws_ami.amazon_linux_2023.name
}

output "ansible_ssh_config" {
  description = "Configuration SSH pour Ansible"
  value = {
    ansible_host                 = aws_eip.main.public_ip
    ansible_user                 = "ec2-user"
    ansible_ssh_private_key_file = local_file.private_key.filename
    env                          = var.environment
    project_name                 = var.project_name
  }
  sensitive = false
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "project_name" {
  description = "Project name"
  value       = var.project_name
}

# DNS Module Outputs (conditionnels)
output "dns_enabled" {
  description = "Whether DNS module is enabled"
  value       = var.enable_dns_module
}

output "dns_zone_id" {
  description = "Route53 hosted zone ID"
  value       = var.enable_dns_module ? module.dns[0].zone_id : null
}

output "dns_zone_name" {
  description = "Route53 hosted zone name"
  value       = var.enable_dns_module ? module.dns[0].zone_name : null
}

output "dns_nameservers" {
  description = "Route53 nameservers (to configure at registrar)"
  value       = var.enable_dns_module ? module.dns[0].nameservers : []
}

output "dns_base_domain" {
  description = "Base domain for services (e.g., oceania.twca.cloud)"
  value       = var.enable_dns_module ? module.dns[0].base_domain : null
}

output "dns_service_fqdns" {
  description = "Map of service FQDNs"
  value       = var.enable_dns_module ? module.dns[0].service_fqdns : {}
}

output "dns_all_fqdns" {
  description = "List of all FQDNs created"
  value       = var.enable_dns_module ? module.dns[0].all_fqdns : []
}

output "dns_config_json" {
  description = "DNS configuration as JSON string (for Ansible export)"
  value       = var.enable_dns_module ? module.dns[0].dns_config : null
}

# Service URLs (HTTPS si DNS activé, HTTP sinon)
output "prometheus_url" {
  description = "Prometheus access URL"
  value       = var.enable_dns_module ? "https://prometheus.${module.dns[0].base_domain}" : "http://${aws_eip.main.public_ip}:9090"
}

output "grafana_url" {
  description = "Grafana access URL"
  value       = var.enable_dns_module ? "https://grafana.${module.dns[0].base_domain}" : "http://${aws_eip.main.public_ip}:3000"
}

output "alertmanager_url" {
  description = "Alertmanager access URL"
  value       = var.enable_dns_module ? "https://alertmanager.${module.dns[0].base_domain}" : "http://${aws_eip.main.public_ip}:9093"
}

output "loki_url" {
  description = "Loki access URL"
  value       = var.enable_dns_module ? "https://loki.${module.dns[0].base_domain}" : "http://${aws_eip.main.public_ip}:3100"
}

output "traefik_dashboard_url" {
  description = "Traefik dashboard URL"
  value       = var.enable_dns_module ? "https://traefik.${module.dns[0].base_domain}" : "http://${aws_eip.main.public_ip}:8080"
}

output "cadvisor_url" {
  description = "cAdvisor access URL"
  value       = var.enable_dns_module ? "https://cadvisor.${module.dns[0].base_domain}" : "http://${aws_eip.main.public_ip}:8080"
}
