# Data source pour récupérer la zone Route53 existante si create_zone = false
data "aws_route53_zone" "existing" {
  count   = var.create_zone ? 0 : 1
  zone_id = var.zone_id
}

# Identité AWS actuelle pour les tags
data "aws_caller_identity" "current" {}

# Région AWS actuelle
data "aws_region" "current" {}
