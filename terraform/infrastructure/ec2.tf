# EC2 Instance
resource "aws_instance" "main" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.main.key_name
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.ec2.id]
  associate_public_ip_address = var.enable_public_ip
  monitoring                  = var.enable_detailed_monitoring
  disable_api_termination     = var.enable_termination_protection
  iam_instance_profile        = aws_iam_instance_profile.ec2.name

  # Force IMDSv2 (protection SSRF)
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # Force IMDSv2
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  root_block_device {
    volume_type           = var.root_volume_type
    volume_size           = var.root_volume_size
    encrypted             = true
    delete_on_termination = true

    tags = {
      Name    = "${var.project_name}-${var.environment}-root-volume"
      Purpose = "EC2RootVolume"
    }
  }

  tags = {
    Name    = "${upper(substr(var.project_name, 0, 1))}${substr(var.project_name, 1, -1)}-${var.environment}-app-server"
    Purpose = "ApplicationServer"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Elastic IP for the instance
resource "aws_eip" "main" {
  instance = aws_instance.main.id
  domain   = "vpc"

  tags = {
    Name    = "${var.project_name}-${var.environment}-eip"
    Purpose = "EC2ElasticIP"
  }

  depends_on = [aws_instance.main]
}
