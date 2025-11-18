# Latest Amazon Linux 2023 AMI
# Recherche l'AMI Amazon Linux 2023 la plus récente pour x86_64
# Si aucune AMI n'est trouvée, Terraform échouera avec un message clair
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# Validation : Vérifier qu'une AMI a bien été trouvée
resource "null_resource" "ami_validation" {
  triggers = {
    ami_id = data.aws_ami.amazon_linux_2023.id
  }

  provisioner "local-exec" {
    command = "echo '✅ AMI validée: ${data.aws_ami.amazon_linux_2023.id} (${data.aws_ami.amazon_linux_2023.name})'"
  }
}

# Default VPC
data "aws_vpc" "default" {
  default = true
}

# Get availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Get existing subnets in default VPC to avoid CIDR conflicts
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Get the internet gateway (should exist in default VPC)
data "aws_internet_gateway" "default" {
  filter {
    name   = "attachment.vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Get the main route table for default VPC
data "aws_route_table" "default" {
  vpc_id = data.aws_vpc.default.id

  filter {
    name   = "association.main"
    values = ["true"]
  }
}

# Create a public subnet in the default VPC
# Using 172.31.255.0/24 to minimize conflict risk with default subnets (typically 172.31.0.0/20, 172.31.16.0/20, etc.)
resource "aws_subnet" "public" {
  vpc_id                  = data.aws_vpc.default.id
  cidr_block              = "172.31.255.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name    = "${var.project_name}-${var.environment}-public-subnet"
    Purpose = "PublicSubnet"
  }
}

# Associate the subnet with the main route table (for internet access)
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = data.aws_route_table.default.id
}
