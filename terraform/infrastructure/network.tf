# Security Group for EC2 instance
resource "aws_security_group" "ec2" {
  name_prefix = "${var.project_name}-${var.environment}-ec2-"
  description = "Security group for ${var.project_name} EC2 instance"
  vpc_id      = data.aws_vpc.default.id

  # SSH access from allowed IPs
  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_ips
  }

  # HTTP access from anywhere
  ingress {
    description = "HTTP access"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS access from anywhere
  ingress {
    description = "HTTPS access"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Grafana access from allowed IPs
  ingress {
    description = "Grafana access"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_ips
  }

  # Prometheus access from allowed IPs
  ingress {
    description = "Prometheus access"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_ips
  }

  # Alertmanager access from allowed IPs
  ingress {
    description = "Alertmanager access"
    from_port   = 9093
    to_port     = 9093
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_ips
  }

  # Node Exporter access from allowed IPs
  ingress {
    description = "Node Exporter access"
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_ips
  }

  # cAdvisor access from allowed IPs
  ingress {
    description = "cAdvisor access"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_ips
  }

  # Loki access from allowed IPs
  ingress {
    description = "Loki access"
    from_port   = 3100
    to_port     = 3100
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_ips
  }

  # Alloy Web UI access from allowed IPs
  ingress {
    description = "Alloy Web UI access"
    from_port   = 12345
    to_port     = 12345
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_ips
  }

  # All outbound traffic
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_name}-${var.environment}-ec2-sg"
    Purpose = "EC2SecurityGroup"
  }

  lifecycle {
    create_before_destroy = true
  }
}
