#!/bin/bash
set -e

echo "🔄 Mise à jour de l'inventaire Ansible depuis Terraform..."

# Aller dans le répertoire Terraform
cd "$(dirname "$0")/../terraform/infrastructure"

# Vérifier que Terraform est initialisé
if [ ! -d ".terraform" ]; then
    echo "❌ Terraform n'est pas initialisé dans terraform/infrastructure"
    echo "Exécutez 'terraform init' d'abord"
    exit 1
fi

# Récupérer les outputs Terraform
echo "📤 Récupération des outputs Terraform..."
IP=$(terraform output -raw instance_public_ip 2>/dev/null)
KEY_PATH=$(terraform output -raw private_key_path 2>/dev/null)
PROJECT=$(terraform output -raw project_name 2>/dev/null)
ENV=$(terraform output -raw environment 2>/dev/null)

# Vérifier que tous les outputs sont disponibles
if [ -z "$IP" ] || [ -z "$KEY_PATH" ] || [ -z "$PROJECT" ] || [ -z "$ENV" ]; then
    echo "❌ Impossible de récupérer les outputs Terraform"
    echo "Assurez-vous que l'infrastructure est déployée (terraform apply)"
    exit 1
fi

# Revenir dans le répertoire Ansible
cd "../../ansible"

# Créer le répertoire inventory s'il n'existe pas
mkdir -p inventory

# Générer le fichier d'inventaire
INVENTORY_FILE="inventory/${ENV}.yml"

cat > "$INVENTORY_FILE" <<EOF
all:
  children:
    oceania:
      hosts:
        oceania-${ENV}:
          ansible_host: ${IP}
          ansible_user: ec2-user
          ansible_ssh_private_key_file: ${KEY_PATH}
          ansible_python_interpreter: /usr/bin/python3
      vars:
        env: ${ENV}
        project_name: ${PROJECT}
EOF

echo "✅ Inventaire généré: ${INVENTORY_FILE}"
echo ""
echo "📋 Configuration:"
echo "  Environnement: ${ENV}"
echo "  Projet: ${PROJECT}"
echo "  IP: ${IP}"
echo "  Clé SSH: ${KEY_PATH}"
echo ""
echo "🎯 Pour tester la connectivité:"
echo "  ansible all -m ping"
