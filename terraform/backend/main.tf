# Data sources pour récupérer les informations AWS
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Génération d'un suffixe aléatoire pour garantir l'unicité
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# Bucket S3 pour stocker le tfstate
resource "aws_s3_bucket" "tfstate" {
  bucket        = "${lower(var.project_name)}-${lower(var.environment)}-tfstate-${random_id.bucket_suffix.hex}"
  force_destroy = false

  tags = {
    Purpose = "TerraformStateBackend"
  }
}

# Configuration du versioning S3
resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Disabled"
  }

  depends_on = [aws_s3_bucket_public_access_block.tfstate]
}

# Chiffrement server-side du bucket S3
resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }

  depends_on = [aws_s3_bucket_public_access_block.tfstate]
}

# Bloquer tout accès public au bucket
resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Lifecycle policy pour les anciennes versions (créée conditionnellement)
# Cette ressource n'est créée QUE si enable_versioning = true
# Elle permet de :
# - Supprimer les anciennes versions non-courantes après 90 jours (économie de coûts)
# - Nettoyer les uploads multipart incomplets après 7 jours
resource "aws_s3_bucket_lifecycle_configuration" "tfstate" {
  count  = var.enable_versioning ? 1 : 0
  bucket = aws_s3_bucket.tfstate.id

  rule {
    id     = "cleanup_old_versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 90
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }

  depends_on = [aws_s3_bucket_versioning.tfstate]
}

# Table DynamoDB pour le state locking
resource "aws_dynamodb_table" "tfstate_lock" {
  name         = "${lower(var.project_name)}-${lower(var.environment)}-tfstate-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  deletion_protection_enabled = false

  tags = {
    Purpose = "TerraformStateBackend"
  }
}
