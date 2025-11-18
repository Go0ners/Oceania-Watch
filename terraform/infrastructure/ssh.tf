# Generate ED25519 SSH key pair
resource "tls_private_key" "ssh_key" {
  algorithm = "ED25519"
}

# Create AWS key pair
resource "aws_key_pair" "main" {
  key_name   = "${var.project_name}-${var.environment}-key"
  public_key = tls_private_key.ssh_key.public_key_openssh

  tags = {
    Name    = "${var.project_name}-${var.environment}-key"
    Purpose = "EC2SSHAccess"
  }
}

# Create SSH directory if it doesn't exist
resource "null_resource" "create_ssh_directory" {
  provisioner "local-exec" {
    command = "mkdir -p ${pathexpand(var.ssh_key_directory)} && chmod 700 ${pathexpand(var.ssh_key_directory)}"
  }
}

# Save private key locally
resource "local_file" "private_key" {
  content         = tls_private_key.ssh_key.private_key_openssh
  filename        = pathexpand("${var.ssh_key_directory}/${var.project_name}-${var.environment}.pem")
  file_permission = "0600"

  depends_on = [null_resource.create_ssh_directory]
}

# Save public key locally
resource "local_file" "public_key" {
  content         = tls_private_key.ssh_key.public_key_openssh
  filename        = pathexpand("${var.ssh_key_directory}/${var.project_name}-${var.environment}.pub")
  file_permission = "0644"

  depends_on = [null_resource.create_ssh_directory]
}
