# OceaniaWatch - Infrastructure as Code

**Déploiement automatisé d'infrastructure AWS avec Terraform et Ansible**

[![Infrastructure](https://img.shields.io/badge/Infrastructure-AWS-orange)](https://aws.amazon.com)
[![IaC](https://img.shields.io/badge/IaC-Terraform-purple)](https://terraform.io)
[![Config](https://img.shields.io/badge/Config-Ansible-red)](https://ansible.com)
[![Status](https://img.shields.io/badge/Status-Production_Ready-green)](.)

---

## 📋 Description

**OceaniaWatch** est une solution Infrastructure as Code (IaC) complète permettant le déploiement automatisé d'une infrastructure AWS sécurisée et évolutive. Le projet combine Terraform pour le provisioning d'infrastructure et Ansible pour la configuration post-déploiement.

### Objectifs

- **Automatisation complète** du cycle de vie infrastructure (déploiement, configuration, destruction)
- **Reproductibilité** des environnements (dev, staging, prod)
- **Sécurité** par défaut (chiffrement, clés SSH, state distant)
- **Simplicité d'utilisation** via un script unifié (`oceania`)

---

## 🏗️ Architecture

### Vue d'ensemble

```
┌─────────────────────────────────────────────────────────────┐
│                         AWS Cloud                           │
│                         Region: us-east-1                   │
│                                                             │
│  ┌────────────────────┐                                     │
│  │  Backend Terraform │                                     │
│  │  ┌──────────────┐  │                                     │
│  │  │ S3 Bucket    │  │  State Storage + Versioning         │
│  │  │ + Locking    │  │                                     │
│  │  └──────────────┘  │                                     │
│  │  ┌──────────────┐  │                                     │
│  │  │ DynamoDB     │  │  Compatibilité                      │
│  │  └──────────────┘  │                                     │
│  └────────────────────┘                                     │
│           │                                                 │
│           │ Remote State                                    │
│           ▼                                                 │
│  ┌────────────────────────────────────────────────────┐     │
│  │  VPC (Default)                                     │     │
│  │                                                    │     │
│  │  ┌───────────────────────────────────────────┐     │     │
│  │  │  Public Subnet                            │     │     │
│  │  │                                           │     │     │
│  │  │  ┌──────────────────────────────────┐     │     │     │
│  │  │  │  EC2 Instance                    │     │     │     │
│  │  │  │  - Amazon Linux 2023             │     │     │     │
│  │  │  │  - t3.large (2 vCPU, 8GB RAM)    │     │     │     │
│  │  │  │  - Docker 29.0.0                 │     │     │     │
│  │  │  │  - Docker Compose 2.40.3         │     │     │     │
│  │  │  │  - 100GB EBS gp3 (encrypted)     │     │     │     │
│  │  │  └──────────────────────────────────┘     │     │     │
│  │  │           │                               │     │     │
│  │  │           │                               │     │     │
│  │  │  ┌────────▼─────────┐                     │     │     │
│  │  │  │  Elastic IP      │  44.x.x.x           │     │     │
│  │  │  └──────────────────┘                     │     │     │
│  │  │           │                               │     │     │
│  │  │  ┌────────▼─────────┐                     │     │     │
│  │  │  │  Security Group  │                     │     │     │
│  │  │  │  - SSH: 22       │  Custom IPs         │     │     │
│  │  │  │  - HTTP: 80      │  0.0.0.0/0          │     │     │
│  │  │  │  - HTTPS: 443    │  0.0.0.0/0          │     │     │
│  │  │  └──────────────────┘                     │     │     │
│  │  └───────────────────────────────────────────┘     │     │
│  └────────────────────────────────────────────────────┘     │
│                                                             │
│  ┌────────────────┐                                         │
│  │  SSH Keys      │  ED25519 (auto-generated)               │
│  │  ~/.ssh/oceania│                                         │
│  └────────────────┘                                         │
└─────────────────────────────────────────────────────────────┘

        │
        │ SSH Connection
        ▼
    ┌────────────┐
    │   Local    │
    │  Machine   │
    └────────────┘
```

### Flux de Déploiement

```
┌──────────────┐
│ ./oceania    │
│   deploy     │
└──────┬───────┘
       │
       ▼
┌──────────────────────────────────────┐
│  Étape 1: Backend Terraform          │
│  ├─ Création bucket S3               │
│  ├─ Activation versioning            │
│  ├─ Configuration S3 locking         │
│  └─ Création table DynamoDB          │
└──────────┬───────────────────────────┘
           │
           ▼
┌──────────────────────────────────────┐
│  Étape 2: Infrastructure EC2         │
│  ├─ Génération clés SSH ED25519      │
│  ├─ Création instance EC2            │
│  ├─ Allocation Elastic IP            │
│  ├─ Configuration Security Group     │
│  └─ Attachement volume EBS           │
└──────────┬───────────────────────────┘
           │
           ▼
┌──────────────────────────────────────┐
│  Étape 3: Configuration Ansible      │
│  ├─ Installation Docker 29.0.0       │
│  ├─ Installation Docker Compose      │
│  ├─ Installation outils système      │
│  ├─ Configuration utilisateurs       │
│  └─ Validation complète              │
└──────────────────────────────────────┘
```

---

## 📁 Structure du Projet

```
OceaniaWatch/
├── oceania                          # Script principal de déploiement
├── .gitignore                       # Protection des secrets
├── README.md                        # Ce fichier
│
├── terraform/                       # Infrastructure as Code
│   ├── backend/                     # Étape 1: Backend Terraform
│   │   ├── main.tf                  # Configuration S3 + DynamoDB
│   │   ├── provider.tf              # Provider AWS + Random
│   │   ├── variables.tf             # Variables du backend
│   │   ├── outputs.tf               # Outputs (bucket name, region)
│   │   └── terraform.tfvars.example # Template
│   │
│   └── infrastructure/              # Étape 2: Infrastructure EC2
│       ├── main.tf                  # Configuration backend distant
│       ├── ec2.tf                   # Instance EC2 + Elastic IP
│       ├── network.tf               # VPC, Subnet, Security Group
│       ├── ssh.tf                   # Génération clés SSH ED25519
│       ├── data.tf                  # Data sources (AMI, VPC)
│       ├── variables.tf             # Variables infrastructure
│       ├── outputs.tf               # Outputs (IP, SSH command)
│       ├── terraform.tfvars.example # Template
│       └── backend.hcl.example      # Template backend
│
├── ansible/                         # Configuration Management
│   ├── ansible.cfg                  # Configuration Ansible
│   ├── requirements.yml             # Collections requises
│   ├── update-inventory.sh          # Script MAJ inventaire
│   │
│   ├── inventory/                   # Inventaires
│   │   ├── dev.yml                  # Template inventaire dev
│   │   └── group_vars/
│   │       └── all.yml              # Variables globales
│   │
│   ├── playbooks/                   # Playbooks Ansible
│   │   ├── setup-instance.yml       # Configuration complète
│   │   ├── validate-setup.yml       # Validation installation
│   │   └── rollback-docker.yml      # Rollback Docker
│   │
│   └── roles/                       # Rôles modulaires
│       ├── docker/                  # Installation Docker
│       │   ├── defaults/main.yml
│       │   ├── tasks/main.yml
│       │   └── handlers/main.yml
│       ├── common-tools/            # Outils système
│       │   ├── defaults/main.yml
│       │   └── tasks/main.yml
│       └── system-update/           # Mise à jour système
│           ├── tasks/main.yml
│           └── handlers/main.yml
│
└── .backups/                        # Sauvegardes automatiques
    └── backup-pre-*-YYYYMMDD-HHMMSS/
```

---

## 🔧 Technologies

### Infrastructure as Code

| Technologie | Version | Rôle |
|-------------|---------|------|
| **Terraform** | >= 1.13.0 | Provisioning infrastructure |
| **AWS Provider** | ~> 6.20.0 | Gestion ressources AWS |
| **TLS Provider** | ~> 4.1.0 | Génération clés SSH |
| **Local Provider** | ~> 2.5.3 | Fichiers locaux |
| **Null Provider** | ~> 3.2.4 | Provisioners |
| **Random Provider** | ~> 3.7.2 | Génération IDs aléatoires |

### Configuration Management

| Technologie | Version | Rôle |
|-------------|---------|------|
| **Ansible** | >= 2.9 | Configuration post-déploiement |
| **community.general** | >= 11.4.1 | Collection Ansible |
| **community.docker** | >= 4.8.2 | Gestion Docker |
| **ansible.posix** | >= 2.1.0 | Modules POSIX |

### Infrastructure Déployée

| Composant | Version/Type | Description |
|-----------|--------------|-------------|
| **OS** | Amazon Linux 2023 | Système d'exploitation |
| **Docker** | 29.0.0 | Containerisation |
| **Docker Compose** | 2.40.3 | Orchestration containers |
| **Instance** | t3.large | 2 vCPU, 8GB RAM |
| **Storage** | 100GB EBS gp3 | Chiffré AES256 |
| **Réseau** | Elastic IP | IP publique fixe |

### Outils Installés

- **git** - Version control
- **vim** - Éditeur texte
- **htop** - Monitoring processus
- **tree** - Visualisation arborescence
- **jq** - Parser JSON
- **wget, curl** - Téléchargement fichiers
- **unzip** - Extraction archives
- **net-tools** - Outils réseau

---

## ⚙️ Prérequis

### Outils Locaux

#### Obligatoires

```bash
# Terraform
terraform --version  # >= 1.13.0
# Installation: https://developer.hashicorp.com/terraform/downloads

# Ansible
ansible --version  # >= 2.9
# Installation: pip install ansible

# AWS CLI
aws --version
# Installation: https://aws.amazon.com/cli/
```

#### Optionnels (recommandés)

```bash
# Scanner de sécurité
tfsec checkov gitleaks

# Outils de développement
tree jq
```

### Accès et Permissions AWS

#### Configuration AWS CLI

```bash
aws configure
# AWS Access Key ID: VOTRE_ACCESS_KEY
# AWS Secret Access Key: VOTRE_SECRET_KEY
# Default region: us-east-1
# Default output format: json

# Tester
aws sts get-caller-identity
```

#### Permissions IAM Requises

Votre utilisateur/rôle AWS doit avoir les permissions suivantes :

**Pour le Backend (S3 + DynamoDB)**:
- `s3:CreateBucket`, `s3:DeleteBucket`, `s3:PutBucket*`, `s3:GetBucket*`
- `s3:PutObject`, `s3:GetObject`, `s3:DeleteObject`
- `dynamodb:CreateTable`, `dynamodb:DeleteTable`, `dynamodb:DescribeTable`

**Pour l'Infrastructure (EC2 + Réseau)**:
- `ec2:*` (instances, security groups, elastic IPs, volumes)
- `vpc:*` (si création VPC custom)

**Politique IAM minimale recommandée**: PowerUserAccess ou EC2FullAccess + S3FullAccess + DynamoDBFullAccess

---

## 🚀 Installation et Déploiement

### Script `oceania` - Outil Principal

Le script `oceania` est un outil Bash unifié qui orchestre tout le cycle de vie de l'infrastructure.

#### Fonctionnalités

- ✅ Vérification automatique des prérequis (Terraform, Ansible, AWS CLI)
- ✅ Validation des credentials AWS
- ✅ Gestion d'état persistante (`.oceania-state`)
- ✅ Sauvegardes automatiques avant actions destructives
- ✅ Génération automatique de `backend.hcl`
- ✅ Mode quiet pour CI/CD (`--quiet`)

#### Commandes Disponibles

```bash
./oceania deploy        # Déploiement complet (backend + infra + config)
./oceania status        # Afficher l'état du déploiement
./oceania destroy       # Détruire infrastructure EC2 (garder backend)
./oceania destroy-all   # Tout détruire (EC2 + backend)
./oceania help          # Aide complète
```

---

### 📖 Guide de Déploiement Complet

#### Option 1: Déploiement Automatique (Recommandé)

**Durée**: 5-10 minutes

```bash
# 1. Configurer les variables Terraform
cd terraform/backend
cp terraform.tfvars.example terraform.tfvars
vim terraform.tfvars
# Éditer: project_name, environment, aws_region

cd ../infrastructure
cp terraform.tfvars.example terraform.tfvars
vim terraform.tfvars
# Éditer: IMPORTANT - allowed_ssh_ips = ["VOTRE_IP/32"]

# 2. Retour à la racine
cd ../..

# 3. Déployer tout en une commande
./oceania deploy

# Le script va:
# - Vérifier Terraform, Ansible, AWS CLI installés
# - Valider vos credentials AWS
# - Créer une sauvegarde automatique
# - Déployer le backend Terraform (S3 + DynamoDB)
# - Générer automatiquement backend.hcl avec le bon bucket
# - Déployer l'infrastructure EC2
# - Générer les clés SSH ED25519
# - Configurer l'instance avec Ansible (Docker + outils)
# - Valider l'installation complète

# 4. Se connecter
# La commande SSH s'affiche à la fin:
ssh -i ~/.ssh/oceania/oceania-watch-dev.pem ec2-user@<IP>
```

#### Option 2: Déploiement Manuel (Étape par Étape)

**Pour comprendre chaque étape en détail**

##### Étape 1: Backend Terraform (2-3 min)

```bash
cd terraform/backend

# Configuration
cp terraform.tfvars.example terraform.tfvars
vim terraform.tfvars

# Déploiement
terraform init
terraform plan
terraform apply

# Noter le bucket name
terraform output s3_bucket_name
# Exemple: oceania-watch-dev-tfstate-abc12345

cd ../..
```

##### Étape 2: Infrastructure EC2 (3-5 min)

```bash
cd terraform/infrastructure

# Configuration des variables
cp terraform.tfvars.example terraform.tfvars
vim terraform.tfvars
# IMPORTANT: Modifier allowed_ssh_ips = ["VOTRE_IP/32"]

# Configuration du backend
cp backend.hcl.example backend.hcl
vim backend.hcl
# Remplacer "your-bucket-name-here" par le bucket de l'étape 1

# Déploiement
terraform init -backend-config=backend.hcl
terraform plan
terraform apply

# Récupérer les infos
terraform output ssh_connection_string
terraform output instance_public_ip

cd ../..
```

##### Étape 3: Configuration Ansible (2-3 min)

```bash
cd ansible

# Installer les collections Ansible
ansible-galaxy collection install -r requirements.yml

# Générer l'inventaire depuis Terraform
bash update-inventory.sh

# Tester la connectivité
ansible all -m ping

# Configuration complète
ansible-playbook playbooks/setup-instance.yml

# Validation
ansible-playbook playbooks/validate-setup.yml

cd ..
```

#### Option 3: Déploiement CI/CD (Mode Quiet)

```bash
# Mode silencieux (pas d'interactions)
./oceania deploy --quiet

# Idéal pour:
# - Pipelines CI/CD (GitHub Actions, GitLab CI, Jenkins)
# - Automatisation scripts
# - Déploiements programmés
```

---

### 🔄 Gestion du Cycle de Vie

#### Vérifier l'État

```bash
./oceania status

# Affiche:
# - État du backend (bucket S3)
# - État de l'infrastructure (instance running/stopped, IP)
# - État de la configuration (Docker installé, version)
```

#### Arrêter l'Instance (Économiser)

```bash
# Via AWS CLI
aws ec2 stop-instances --instance-ids $(cd terraform/infrastructure && terraform output -raw instance_id)

# Coût: ~$9/mois (volume EBS seulement) au lieu de ~$70/mois
```

#### Démarrer l'Instance

```bash
# Via AWS CLI
aws ec2 start-instances --instance-ids $(cd terraform/infrastructure && terraform output -raw instance_id)

# Attendre le démarrage
aws ec2 wait instance-running --instance-ids $(cd terraform/infrastructure && terraform output -raw instance_id)

# L'Elastic IP reste la même, pas besoin de reconfigurer
```

#### Détruire l'Infrastructure EC2 (Garder Backend)

```bash
./oceania destroy

# Supprime:
# - Instance EC2
# - Elastic IP
# - Security Group
# - Clés SSH AWS (fichiers locaux conservés)

# Conserve:
# - Backend S3 (state)
# - Table DynamoDB
# - Possibilité de redéployer rapidement
```

#### Tout Détruire (EC2 + Backend)

```bash
./oceania destroy-all

# ATTENTION: Irréversible !

# Supprime tout:
# - Infrastructure EC2
# - Backend S3 (avec vidage automatique du bucket)
# - Table DynamoDB

# Une sauvegarde est créée dans .backups/
```

---

## 🔐 Gestion des Secrets

### Fichiers Sensibles

#### Non Versionnés (Protégés par .gitignore)

```bash
# Terraform
terraform/backend/terraform.tfvars          # Config backend
terraform/infrastructure/terraform.tfvars   # Config infra + IPs SSH
terraform/infrastructure/backend.hcl        # Nom du bucket S3
*.tfstate                                   # État infrastructure
.terraform/                                 # Cache Terraform

# SSH
~/.ssh/oceania/*.pem                        # Clés SSH privées
~/.ssh/oceania/*.pub                        # Clés SSH publiques

# Script
.oceania-state                              # État du déploiement
.backups/                                   # Sauvegardes automatiques
```

#### Versionnés (Templates Safe)

```bash
# Templates à copier et remplir
terraform/backend/terraform.tfvars.example
terraform/infrastructure/terraform.tfvars.example
terraform/infrastructure/backend.hcl.example
```

### Bonnes Pratiques

#### 1. Vérifier Avant Commit
#### 2. Scanner les Secrets

```bash
# Scanner le projet
gitleaks detect --verbose
tfsec terraform/
checkov -d terraform/
```

#### 3. Sauvegarder les Clés SSH

```bash
# Copier dans un endroit sûr
cp -r ~/.ssh/oceania ~/secure-backup/

# Puis stocker dans:
# - 1Password
# - AWS Secrets Manager
# - HashiCorp Vault
# - Bitwarden
```

#### 4. Utiliser Ansible Vault (Pour Secrets Applicatifs)

```bash
# Créer un fichier vault
ansible-vault create ansible/group_vars/vault.yml

# Ajouter:
# db_password: "mot_de_passe_sécurisé"
# api_key: "clé_api_secrète"

# Utiliser dans playbooks:
# "{{ db_password }}"
```

#### 5. Variables d'Environnement (Pour CI/CD)

```bash
# Définir dans le CI/CD
export AWS_ACCESS_KEY_ID="..."
export AWS_SECRET_ACCESS_KEY="..."
export TF_VAR_allowed_ssh_ips='["10.0.0.1/32"]'

# Ne jamais hardcoder dans le code
```

---

## 📝 Variables

### Backend Terraform (`terraform/backend/terraform.tfvars`)

| Variable | Type | Défaut | Description |
|----------|------|--------|-------------|
| `project_name` | string | - | Nom du projet (lettres minuscules + tirets) |
| `environment` | string | "dev" | dev, staging, prod |
| `aws_region` | string | "us-east-1" | Région AWS |
| `enable_versioning` | bool | true | Versioning S3 (recommandé) |

**Exemple**:
```hcl
project_name      = "oceania-watch"
environment       = "dev"
aws_region        = "us-east-1"
enable_versioning = true
```

### Infrastructure (`terraform/infrastructure/terraform.tfvars`)

| Variable | Type | Défaut | Description |
|----------|------|--------|-------------|
| `project_name` | string | - | Nom du projet (doit correspondre au backend) |
| `environment` | string | "dev" | Environnement |
| `aws_region` | string | "us-east-1" | Région AWS |
| `allowed_ssh_ips` | list(string) | ["0.0.0.0/0"] | ⚠️ IPs autorisées SSH (à restreindre !) |
| `instance_type` | string | "t3.large" | Type d'instance EC2 |
| `root_volume_size` | number | 100 | Taille volume en GB |
| `root_volume_type` | string | "gp3" | Type de volume EBS |
| `enable_public_ip` | bool | true | Activer IP publique |
| `enable_detailed_monitoring` | bool | false | Monitoring CloudWatch détaillé |
| `enable_termination_protection` | bool | false | Protection contre suppression |
| `ssh_key_directory` | string | "~/.ssh/oceania" | Dossier clés SSH |

**Exemple Sécurisé**:
```hcl
aws_region        = "us-east-1"
project_name      = "oceania-watch"
environment       = "prod"
allowed_ssh_ips   = ["203.0.113.45/32"]  # Votre IP seulement !
instance_type     = "t3.large"
root_volume_size  = 100

# Production
enable_detailed_monitoring    = true
enable_termination_protection = true
```

### Backend Config (`terraform/infrastructure/backend.hcl`)

| Variable | Valeur | Description |
|----------|--------|-------------|
| `bucket` | oceania-watch-dev-tfstate-xxx | Nom du bucket S3 (depuis étape 1) |
| `key` | infrastructure/terraform.tfstate | Chemin du state |
| `region` | us-east-1 | Région AWS |
| `use_lockfile` | true | S3 native locking (Terraform >= 1.11) |
| `encrypt` | true | Chiffrement du state |

**Note**: Ce fichier est généré automatiquement par `./oceania deploy`

---

## 🧪 Tests

### Tests de Connectivité

```bash
# 1. Tester l'état général
./oceania status

# 2. Tester SSH
ssh -i ~/.ssh/oceania/oceania-watch-dev.pem ec2-user@<IP>

# 3. Tester Ansible
cd ansible
ansible all -m ping
```

### Tests de Configuration

```bash
# Validation Ansible complète
cd ansible
ansible-playbook playbooks/validate-setup.yml

# Vérifications:
# ✓ Docker installé et version correcte
# ✓ Docker Compose installé
# ✓ Utilisateur ec2-user dans groupe docker
# ✓ Outils système présents
# ✓ Services démarrés
```

### Tests de Sécurité

```bash
# 1. Scanner Terraform
tfsec terraform/

# 2. Scanner secrets
gitleaks detect --verbose

# 3. Audit complet
checkov -d terraform/
```

### Tests d'Infrastructure

```bash
# Via Terraform
cd terraform/infrastructure
terraform plan  # Doit afficher "No changes"
terraform output

# Vérifier les ressources AWS
aws ec2 describe-instances --filters "Name=tag:Project,Values=oceania-watch"
aws s3 ls | grep oceania-watch
```

### Tests de Destruction/Recréation

```bash
# Test du cycle complet
./oceania destroy       # Détruire infra
./oceania deploy        # Redéployer
# La configuration doit être identique

# Test destruction totale
./oceania destroy-all   # Tout détruire
./oceania deploy        # Tout recréer
# Nouveau bucket S3 avec nouveau suffixe
```

---

## 💰 Coûts AWS (Estimation us-east-1)

### Coûts Mensuels

| Ressource | Running 24/7 | Stopped | Description |
|-----------|--------------|---------|-------------|
| **Instance t3.large** | ~$60/mois | $0 | 2 vCPU, 8GB RAM |
| **Volume EBS 100GB gp3** | ~$8/mois | ~$8/mois | Stockage persistant |
| **Elastic IP** | $0 | $0 | Gratuit si attaché |
| **S3 Bucket** | <$1/mois | <$1/mois | State Terraform |
| **DynamoDB Table** | <$0.50/mois | <$0.50/mois | Locking (si utilisé) |
| **Data Transfer** | Variable | - | Selon utilisation |
| **Total** | **~$70/mois** | **~$9/mois** | - |

### Optimisation des Coûts

```bash
# Arrêter l'instance quand inutilisée
aws ec2 stop-instances --instance-ids <ID>
# Économie: ~$60/mois

# Utiliser instance plus petite (dev/staging)
instance_type = "t3.medium"  # ~$30/mois au lieu de $60

# Réduire volume EBS (si suffisant)
root_volume_size = 50  # ~$4/mois au lieu de $8

# Utiliser Savings Plans ou Reserved Instances (prod)
# Économie: jusqu'à 72%
```

**Dernière mise à jour**: 18 Novembre 2024
**Version**: 0.1.0
