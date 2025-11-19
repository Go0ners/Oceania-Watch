# Route53 Hosted Zone (conditionnellement créée)
resource "aws_route53_zone" "main" {
  count = var.create_zone ? 1 : 0
  name  = var.domain_name

  tags = {
    Name        = "${var.project_name}-${var.environment}-zone"
    Purpose     = "DNSHostedZone"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = var.project_name
  }
}

# Local pour récupérer l'ID de zone (créée ou existante)
locals {
  zone_id      = var.create_zone ? aws_route53_zone.main[0].id : data.aws_route53_zone.existing[0].id
  zone_name    = var.create_zone ? aws_route53_zone.main[0].name : data.aws_route53_zone.existing[0].name
  nameservers  = var.create_zone ? aws_route53_zone.main[0].name_servers : data.aws_route53_zone.existing[0].name_servers
  base_domain  = "${var.region_suffix}.${var.domain_name}"
}

# Enregistrement A pour le sous-domaine principal (oceania.twca.cloud)
resource "aws_route53_record" "base" {
  zone_id = local.zone_id
  name    = local.base_domain
  type    = "A"
  ttl     = var.ttl
  records = [var.instance_public_ip]
}

# Enregistrements CNAME pour chaque service (pointant vers oceania.twca.cloud)
resource "aws_route53_record" "services" {
  for_each = toset(var.subdomains)

  zone_id = local.zone_id
  name    = "${each.value}.${local.base_domain}"
  type    = "CNAME"
  ttl     = var.ttl
  records = [local.base_domain]

  depends_on = [aws_route53_record.base]
}

# Wildcard CNAME pour attraper tous les sous-domaines non définis (optionnel)
resource "aws_route53_record" "wildcard" {
  zone_id = local.zone_id
  name    = "*.${local.base_domain}"
  type    = "CNAME"
  ttl     = var.ttl
  records = [local.base_domain]

  depends_on = [aws_route53_record.base]
}
