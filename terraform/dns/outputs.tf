output "zone_id" {
  description = "Route53 hosted zone ID"
  value       = local.zone_id
}

output "zone_name" {
  description = "Route53 hosted zone name"
  value       = local.zone_name
}

output "nameservers" {
  description = "Nameservers for the hosted zone (to configure at domain registrar)"
  value       = local.nameservers
}

output "base_domain" {
  description = "Base domain for services (e.g., oceania.twca.cloud)"
  value       = local.base_domain
}

output "base_record_fqdn" {
  description = "FQDN of the base A record"
  value       = aws_route53_record.base.fqdn
}

output "service_fqdns" {
  description = "Map of service names to their FQDNs"
  value = {
    for subdomain in var.subdomains :
    subdomain => aws_route53_record.services[subdomain].fqdn
  }
}

output "all_fqdns" {
  description = "List of all FQDNs created (base + services)"
  value = concat(
    [aws_route53_record.base.fqdn],
    [for record in aws_route53_record.services : record.fqdn]
  )
}

output "wildcard_fqdn" {
  description = "Wildcard FQDN"
  value       = aws_route53_record.wildcard.fqdn
}

output "dns_config" {
  description = "DNS configuration for Ansible (JSON exportable)"
  value = jsonencode({
    zone_id       = local.zone_id
    zone_name     = local.zone_name
    base_domain   = local.base_domain
    base_fqdn     = aws_route53_record.base.fqdn
    instance_ip   = var.instance_public_ip
    nameservers   = local.nameservers
    ttl           = var.ttl
    services      = {
      for subdomain in var.subdomains :
      subdomain => {
        fqdn = aws_route53_record.services[subdomain].fqdn
        name = aws_route53_record.services[subdomain].name
      }
    }
    wildcard_fqdn = aws_route53_record.wildcard.fqdn
    aws_region    = data.aws_region.current.name
  })
}
