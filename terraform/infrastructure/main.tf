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
