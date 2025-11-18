output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.main.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_eip.main.public_ip
}

output "instance_private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = aws_instance.main.private_ip
}

output "instance_public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = aws_eip.main.public_dns
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.ec2.id
}

output "key_pair_name" {
  description = "Name of the AWS key pair"
  value       = aws_key_pair.main.key_name
}

output "private_key_path" {
  description = "Path to the private SSH key"
  value       = local_file.private_key.filename
}

output "public_key_path" {
  description = "Path to the public SSH key"
  value       = local_file.public_key.filename
}

output "ssh_connection_string" {
  description = "SSH connection command"
  value       = "ssh -i ${local_file.private_key.filename} ec2-user@${aws_eip.main.public_ip}"
}

output "ssh_user" {
  description = "Default SSH user for Amazon Linux"
  value       = "ec2-user"
}

output "ami_id" {
  description = "AMI ID used for the instance"
  value       = data.aws_ami.amazon_linux_2023.id
}

output "ami_name" {
  description = "AMI name used for the instance"
  value       = data.aws_ami.amazon_linux_2023.name
}

output "ansible_ssh_config" {
  description = "Configuration SSH pour Ansible"
  value = {
    ansible_host                 = aws_eip.main.public_ip
    ansible_user                 = "ec2-user"
    ansible_ssh_private_key_file = local_file.private_key.filename
    env                          = var.environment
    project_name                 = var.project_name
  }
  sensitive = false
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "project_name" {
  description = "Project name"
  value       = var.project_name
}
