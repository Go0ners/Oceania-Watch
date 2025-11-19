# IAM Role pour EC2 instance
resource "aws_iam_role" "ec2" {
  name = "${var.project_name}-${var.environment}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name    = "${var.project_name}-${var.environment}-ec2-role"
    Purpose = "EC2InstanceRole"
  }
}

# IAM Policy pour Route53 (Traefik DNS Challenge)
resource "aws_iam_policy" "route53_dns_challenge" {
  count       = var.enable_dns_module ? 1 : 0
  name        = "${var.project_name}-${var.environment}-route53-dns-challenge"
  description = "Allow Traefik to perform Route53 DNS challenge for Let's Encrypt"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Route53GetChange"
        Effect = "Allow"
        Action = [
          "route53:GetChange"
        ]
        Resource = "arn:aws:route53:::change/*"
      },
      {
        Sid    = "Route53ManageRecordSets"
        Effect = "Allow"
        Action = [
          "route53:ChangeResourceRecordSets",
          "route53:ListResourceRecordSets"
        ]
        Resource = "arn:aws:route53:::hostedzone/${module.dns[0].zone_id}"
      },
      {
        Sid    = "Route53ListHostedZones"
        Effect = "Allow"
        Action = [
          "route53:ListHostedZonesByName",
          "route53:ListHostedZones"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name    = "${var.project_name}-${var.environment}-route53-policy"
    Purpose = "TraefikDNSChallenge"
  }
}

# Attacher la policy Route53 au rôle EC2
resource "aws_iam_role_policy_attachment" "route53_dns_challenge" {
  count      = var.enable_dns_module ? 1 : 0
  role       = aws_iam_role.ec2.name
  policy_arn = aws_iam_policy.route53_dns_challenge[0].arn
}

# Instance Profile pour l'EC2
resource "aws_iam_instance_profile" "ec2" {
  name = "${var.project_name}-${var.environment}-ec2-profile"
  role = aws_iam_role.ec2.name

  tags = {
    Name    = "${var.project_name}-${var.environment}-ec2-profile"
    Purpose = "EC2InstanceProfile"
  }
}
