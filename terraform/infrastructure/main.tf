terraform {
  required_version = ">= 1.13.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.20.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.1.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5.3"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2.4"
    }
  }

  # Backend S3 avec S3 native state locking (recommandé depuis Terraform 1.11)
  # Note: use_lockfile=true active le verrouillage natif S3 (méthode moderne)
  # La table DynamoDB créée dans le backend n'est pas utilisée mais conservée pour compatibilité
  #
  # Configuration backend via fichier backend.hcl (non versionné)
  # Copier backend.hcl.example vers backend.hcl et remplir les valeurs
  # Initialiser avec : terraform init -backend-config=backend.hcl
  backend "s3" {
    # Configuration fournie via backend.hcl lors de terraform init
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      ManagedBy   = "Terraform"
      Project     = var.project_name
    }
  }
}

# DNS Module (Route53)
module "dns" {
  count  = var.enable_dns_module ? 1 : 0
  source = "../dns"

  # Configuration DNS
  domain_name        = var.dns_domain_name
  region_suffix      = var.dns_region_suffix
  subdomains         = var.dns_subdomains
  instance_public_ip = aws_eip.main.public_ip
  ttl                = var.dns_ttl

  # Zone Route53
  create_zone = var.dns_create_zone
  zone_id     = var.dns_zone_id

  # Métadonnées
  project_name = var.project_name
  environment  = var.environment

  depends_on = [aws_eip.main]
}
