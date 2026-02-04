# OceaniaWatch - Infrastructure as Code

**Déploiement automatisé d'une stack de monitoring sur AWS via Terraform et Ansible**

[![Infrastructure](https://img.shields.io/badge/Infrastructure-AWS-orange)](https://aws.amazon.com)
[![IaC](https://img.shields.io/badge/IaC-Terraform-purple)](https://terraform.io)
[![Config](https://img.shields.io/badge/Config-Ansible-red)](https://ansible.com)
[![Monitoring](https://img.shields.io/badge/Monitoring-Prometheus-orange)](https://prometheus.io)
[![Visualization](https://img.shields.io/badge/Visualization-Grafana-yellow)](https://grafana.com)
[![Status](https://img.shields.io/badge/Status-Production_Ready-green)](.)

---

## 📋 Table des Matières

- [Description](#-description)
- [Architecture](#️-architecture)
- [Stack Monitoring](#-stack-monitoring)
- [Prérequis](#️-prérequis)
- [Installation et Déploiement](#-installation-et-déploiement)
- [Commandes Disponibles](#-commandes-disponibles)
- [Gestion du Cycle de Vie](#-gestion-du-cycle-de-vie)
- [Gestion des Credentials](#-gestion-des-credentials)
- [Monitoring et Observabilité](#-monitoring-et-observabilité)
- [Variables de Configuration](#-variables-de-configuration)
- [Sécurité](#-sécurité)
- [Tests](#-tests)
- [Coûts AWS](#-coûts-aws)
- [Troubleshooting](#-troubleshooting)

---

## 📋 Description

> *"Big Brother is watching you"* - George Orwell, 1984

**OceaniaWatch** est une plateforme de monitoring et d'observabilité complète, inspirée du concept de surveillance omniprésente du roman dystopique *1984*. Tout comme en Oceania où un gouvernement observe et contrôle chaque aspect de la société, OceaniaWatch observe en temps réel l'ensemble de votre infrastructure et a comme ambition d'intervenir pour corriger les divergences d'état.

Cette solution permet de monitorer n'importe quel type d'infrastructure :
- **Cloud providers** : AWS, Azure, GCP, DigitalOcean
- **On-premise** : Serveurs physiques, datacenters privés
- **Services managés** : RDS, Lambda, Kubernetes, etc.
- **Hybride** : Environnements multi-cloud et mixtes

Le projet combine :
- **Terraform** pour le provisioning d'infrastructure
- **Ansible** pour la configuration post-déploiement
- **Docker Compose** pour l'orchestration des services
- **Stack Monitoring** complète (Prometheus, Grafana, Alertmanager, Loki)

### Objectifs

- **Monitoring universel** : Surveiller n'importe quelle infrastructure (cloud, on-prem, hybride)
- **Observabilité complète** : Métriques, logs, alertes en temps réel
- **Déploiement automatisé** : Infrastructure as Code reproductible
- **Multi-provider** : Compatible AWS, Azure, GCP, bare-metal
- **Simplicité** : Gestion unifiée via script `oceania`

### Composants Principaux

| Composant | Technologie | Description |
|-----------|-------------|-------------|
| **Collecte Métriques** | Prometheus | Time-series database, scraping, alerting |
| **Visualisation** | Grafana | Dashboards interactifs, multi-datasources |
| **Logs** | Loki + Alloy | Agrégation et analyse de logs |
| **Alerting** | Alertmanager | Gestion et routage des alertes |
| **Exporters** | Node, cAdvisor | Métriques système et conteneurs |
| **Infrastructure** | Terraform + Ansible | Provisioning et configuration automatisés |
| **Orchestration** | Docker Compose | Déploiement de la stack monitoring |

---

## 🏗️ Architecture

### Vue d'ensemble Infrastructure + Monitoring

```
┌─────────────────────────────────────────────────────────────────────┐
│                              AWS Cloud                              │
│                                                                     │
│  ┌────────────────────┐                                             │
│  │  Backend Terraform │                                             │
│  │  ┌──────────────┐  │  State Storage + Versioning                 │
│  │  │ S3           │  │  Native S3 state locking                    │
│  │  └──────────────┘  │                                             │
│  └────────────────────┘                                             │
│           │                                                         │
│           │ Remote State                                            │
│           ▼                                                         │
│  ┌────────────────────────────────────────────────────────────┐     │
│  │  VPC                                                       │     │
│  │                                                            │     │
│  │  ┌──────────────────────────────────────────────────┐      │     │
│  │  │  EC2 Instance                                    │      │     │
│  │  │  - Amazon Linux 2023                             │      │     │
│  │  │  - Docker + Compose                              │      │     │
│  │  │                                                  │      │     │
│  │  │  ┌────────────────────────────────────────┐      │      │     │
│  │  │  │  Stack Monitoring                      │      │      │     │
│  │  │  │                                        │      │      │     │
│  │  │  │  ┌──────────┐  ┌──────────┐            │      │      │     │
│  │  │  │  │Prometheus│  │ Grafana  │            │      │      │     │
│  │  │  │  │  :9090   │  │  :3000   │            │      │      │     │
│  │  │  │  └────┬─────┘  └────┬─────┘            │      │      │     │
│  │  │  │       │             │                  │      │      │     │
│  │  │  │  ┌────▼─────┐  ┌────▼─────┐            │      │      │     │
│  │  │  │  │  Node    │  │  Loki    │            │      │      │     │
│  │  │  │  │ Exporter │  │  :3100   │            │      │      │     │
│  │  │  │  │  :9100   │  └──────────┘            │      │      │     │
│  │  │  │  └──────────┘                          │      │      │     │
│  │  │  │  ┌──────────┐  ┌──────────┐            │      │      │     │
│  │  │  │  │cAdvisor  │  │Alertmgr  │            │      │      │     │
│  │  │  │  │  :8080   │  │  :9093   │            │      │      │     │
│  │  │  │  └──────────┘  └──────────┘            │      │      │     │
│  │  │  │  ┌──────────┐                          │      │      │     │
│  │  │  │  │  Alloy   │                          │      │      │     │
│  │  │  │  │  :12345  │                          │      │      │     │
│  │  │  │  └──────────┘                          │      │      │     │
│  │  │  └────────────────────────────────────────┘      │      │     │
│  │  │                                                  │      │     │
│  │  │  ┌────────────────┐                              │      │     │
│  │  │  │  Elastic IP    │                              │      │     │
│  │  │  └────────────────┘                              │      │     │
│  │  │  ┌────────────────┐                              │      │     │
│  │  │  │ Security Group │                              │      │     │
│  │  │  └────────────────┘                              │      │     │
│  │  └──────────────────────────────────────────────────┘      │     │
│  └────────────────────────────────────────────────────────────┘     │
│                                                                     │
│  ┌────────────────┐                                                 │
│  │  SSH Keys      │  ED25519                                        │
│  └────────────────┘                                                 │
└─────────────────────────────────────────────────────────────────────┘
        │
        │ SSH + HTTPS
        ▼
    ┌────────────┐
    │   Local    │
    │  Machine   │
    └────────────┘
```

### Flux de Déploiement Complet

```
┌──────────────────┐
│ ./oceania        │
│   deploy-all     │
└────────┬─────────┘
         │
         ▼
┌────────────────────────────────────────┐
│  Étape 1/4: Backend Terraform          │
│  ├─ Création bucket S3                 │
│  ├─ Activation versioning              │
│  ├─ Configuration chiffrement AES256   │
│  └─ Configuration S3 native locking    │
└────────┬───────────────────────────────┘
         │
         ▼
┌────────────────────────────────────────┐
│  Étape 2/4: Infrastructure EC2         │
│  ├─ Génération clés SSH ED25519        │
│  ├─ Création instance EC2              │
│  ├─ Allocation Elastic IP              │
│  ├─ Configuration Security Group       │
│  └─ Attachement volume EBS             │
└────────┬───────────────────────────────┘
         │
         ▼
┌────────────────────────────────────────┐
│  Étape 3/4: Configuration Ansible      │
│  ├─ Installation Docker                │
│  ├─ Installation Docker Compose        │
│  ├─ Installation outils système        │
│  ├─ Configuration utilisateurs         │
│  └─ Validation complète                │
└────────┬───────────────────────────────┘
         │
         ▼
┌────────────────────────────────────────┐
│  Étape 4/4: Stack Monitoring           │
│  ├─ Déploiement Prometheus             │
│  ├─ Déploiement Grafana                │
│  ├─ Déploiement Alertmanager           │
│  ├─ Déploiement Node Exporter          │
│  ├─ Déploiement cAdvisor               │
│  ├─ Déploiement Loki                   │
│  ├─ Déploiement Alloy                  │
│  └─ Validation complète                │
└────────────────────────────────────────┘
```

---

## 📊 Stack Monitoring

### Composants de Monitoring

| Composant | Version | Port | Description |
|-----------|---------|------|-------------|
| **Prometheus** | latest | 9090 | Collecte et stockage des métriques |
| **Grafana** | latest | 3000 | Visualisation et dashboards |
| **Alertmanager** | latest | 9093 | Gestion des alertes |
| **Node Exporter** | latest | 9100 | Métriques système (CPU, RAM, Disk) |
| **cAdvisor** | latest | 8080 | Métriques des conteneurs Docker |
| **Loki** | latest | 3100 | Agrégation de logs |
| **Alloy** | latest | 12345 | Collecte de logs |

### Architecture Monitoring

```
    ÉTRIQUES                                            LOGS
                    
┌──────────────┐     ┌──────────────┐              ┌──────────────┐
│   Système    │     │   Docker     │              │   Système    │
│              │     │              │              │   Docker     │
└──────┬───────┘     └──────┬───────┘              └──────┬───────┘
       │                    │                             │
       ▼                    ▼                             │ logs
┌──────────────┐     ┌──────────────┐                     ▼
│Node Exporter │     │  cAdvisor    │              ┌──────────────┐
│    :9100     │     │    :8080     │              │    Alloy     │
└──────┬───────┘     └──────┬───────┘              │   :12345     │
       │                    │                      └──────┬───────┘
       │    métriques       │                             │
       └────────┬───────────┘                             │ push
                │                                         ▼
                ▼                                  ┌──────────────┐
        ┌──────────────┐                           │     Loki     │
        │  Prometheus  │                           │    :3100     │
        │    :9090     │                           └──────┬───────┘
        └──────┬───────┘                                  │
               │                                          │
               │ query                                    │ query
               │         ┌────────────────────────────────┘
               │         │
               ▼         ▼
            ┌──────────────┐
            │   Grafana    │
            │    :3000     │
            └──────────────┘
                   │
                   │ alerts
                   ▼
            ┌──────────────┐
            │ Alertmanager │
            │    :9093     │
            └──────────────┘
```

### Métriques Collectées

**Système (Node Exporter)** :
- CPU : Utilisation, load average, contexte switches
- Mémoire : Utilisée, disponible, swap
- Disque : Espace, I/O, inodes
- Réseau : Bande passante, paquets, erreurs
- ...

**Conteneurs (cAdvisor)** :
- CPU par conteneur
- Mémoire par conteneur
- Réseau par conteneur
- I/O disque par conteneur
- ...

### Alertes Pré-configurées

| Alerte | Condition | Durée | Sévérité |
|--------|-----------|-------|----------|
| InstanceDown | up == 0 | 5 min | Critical |
| ContainerDown | Conteneur absent | 5 min | Critical |
| PrometheusTargetMissing | Target down | 5 min | Critical |
| PrometheusConfigReloadFailed | Config reload failed | 5 min | Critical |
| HighCPUUsage | CPU > 80% | 10 min | Warning |
| HighMemoryUsage | RAM > 85% | 10 min | Warning |
| DiskSpaceLow | Disque < 15% | 5 min | Warning |
| HighDiskIOUtilization | I/O > 90% | 10 min | Warning |
| InodesLow | Inodes < 10% | 5 min | Warning |
| NetworkReceiveErrors | Erreurs réseau RX | 5 min | Warning |
| NetworkTransmitErrors | Erreurs réseau TX | 5 min | Warning |
| ContainerRestartLoop | > 3 restarts/h | 5 min | Warning |
| ContainerHighCPU | Container CPU > 80% | 10 min | Warning |
| ContainerHighMemory | Container RAM > 85% | 10 min | Warning |
| PrometheusTooManyRestarts | > 2 restarts/h | 5 min | Warning |

### Dashboards Grafana Pré-configurés

| Dashboard | Description |
|-----------|-------------|
| **Node Exporter - Host Metrics** | CPU, RAM, Disk, Network, Load Average |
| **Docker Containers** | CPU, RAM, Network par conteneur, Restarts |
| **Monitoring Stack Health** | Status des services, Scrape metrics, Alertes |
| **Logs Explorer** | Logs Docker via Loki, filtrage par conteneur |

### Recording Rules Prometheus

Des recording rules sont pré-configurées pour optimiser les requêtes :
- `instance:node_cpu_utilization:percent` - CPU usage en %
- `instance:node_memory_utilization:percent` - RAM usage en %
- `instance:node_filesystem_utilization:percent` - Disk usage en %
- `container:cpu_utilization:percent` - CPU conteneur en %
- `container:memory_utilization:percent` - RAM conteneur en %
- `container:restarts:count24h` - Nombre de restarts sur 24h

---

## ⚙️ Prérequis

### Outils Locaux Obligatoires

```bash
# Terraform
terraform --version  # >= 1.13.0
# Installation: https://developer.hashicorp.com/terraform/downloads

# Ansible
ansible --version  # >= 2.9
# Installation: pip install ansible

# AWS CLI
aws --version # >= 2.0
# Installation: https://aws.amazon.com/cli/
```

### Configuration AWS CLI

```bash
aws configure
# AWS Access Key ID: VOTRE_ACCESS_KEY
# AWS Secret Access Key: VOTRE_SECRET_KEY
# Default region: votre région
# Default output format: json

# Tester
aws sts get-caller-identity
```

### Permissions IAM Requises

**Backend (S3 avec native locking)** :
- `s3:*`

**Infrastructure (EC2 + Réseau)** :
- `ec2:*`, `vpc:*`

**Recommandation** : PowerUserAccess ou EC2FullAccess + S3FullAccess

---

## 🚀 Installation et Déploiement

### Quickstart (5 minutes)

```bash
# 1. Configuration interactive (détecte votre IP, configure les variables)
./oceania quickstart

# 2. Déployer TOUT
./oceania deploy-all

# Durée: 10-15 minutes
# Résultat: Infrastructure + Monitoring complets
```

### Déploiement Progressif

```bash
# Déploiement en 2 étapes
./oceania deploy-infra      # 7-10 min
./oceania deploy-monitoring # 3-5 min
```

---

## 🎮 Commandes Disponibles

### Préparation

```bash
# Configuration interactive de l'environnement
./oceania quickstart
# ├─ Vérifie les prérequis (terraform, ansible, aws-cli)
# ├─ Détecte votre IP publique
# ├─ Configure les variables (projet, région, instance)
# └─ Génère les fichiers terraform.tfvars
```

### Déploiement

```bash
# Déploiement complet (recommandé)
./oceania deploy-all
# ├─ Backend Terraform
# ├─ Infrastructure EC2
# ├─ Configuration Ansible
# └─ Stack Monitoring

# Infrastructure seule
./oceania deploy-infra
# ├─ Backend Terraform
# ├─ Infrastructure EC2
# └─ Configuration Ansible

# Monitoring seul (nécessite infra déployée)
./oceania deploy-monitoring
# └─ Stack Monitoring complète
```

### Gestion

```bash
# Afficher les credentials (URLs, logins, passwords)
./oceania credentials

# Régénérer le mot de passe Grafana
./oceania credentials --regenerate

# Voir l'état complet
./oceania status

# Nettoyer les fichiers locaux (avant push git)
./oceania clean

# Détruire infrastructure (garder backend)
./oceania destroy

# Tout détruire (irréversible)
./oceania destroy-all

# Aide
./oceania help
```

### Options

```bash
# Mode verbeux (affiche les détails Terraform)
./oceania -v deploy-all
./oceania --verbose deploy-all

# Mode silencieux (pas d'interactions)
./oceania -q deploy-all
./oceania --quiet deploy-all
```

### Résultat du Déploiement

```
✓ DÉPLOIEMENT COMPLET TERMINÉ AVEC SUCCÈS

Infrastructure complète déployée et configurée !

Connexion SSH:
  ssh -i ~/.ssh/oceania/oceania-watch-dev.pem ec2-user@44.x.x.x

Services de monitoring:
  Prometheus:    http://44.x.x.x:9090
  Grafana:       http://44.x.x.x:3000
  Alertmanager:  http://44.x.x.x:9093
  Node Exporter: http://44.x.x.x:9100/metrics
  cAdvisor:      http://44.x.x.x:8080
  Loki:          http://44.x.x.x:3100
  Alloy:         http://44.x.x.x:12345

Pour gérer l'instance:
  ./oceania credentials - Afficher les logins/passwords
  ./oceania status      - Voir l'état
  ./oceania destroy     - Détruire l'infrastructure
```

---
## 🔄 Gestion du Cycle de Vie

### Vérifier l'État

```bash
./oceania status

# Affiche:
# - État du backend (bucket S3)
# - État de l'infrastructure (instance, IP, état)
# - État de la configuration (Docker, version)
# - État du monitoring (services actifs, URLs)
```

### Arrêter/Démarrer l'Instance

```bash
# Arrêter (économiser ~$60/mois)
aws ec2 stop-instances --instance-ids $(cd terraform/infrastructure && terraform output -raw instance_id)

# Démarrer
aws ec2 start-instances --instance-ids $(cd terraform/infrastructure && terraform output -raw instance_id)
aws ec2 wait instance-running --instance-ids $(cd terraform/infrastructure && terraform output -raw instance_id)
```

### Détruire et Redéployer

```bash
# Détruire infrastructure (garder backend)
./oceania destroy
# Coût: ~$1/mois (S3 seulement)

# Redéployer rapidement
./oceania deploy-infra
./oceania deploy-monitoring

# Tout détruire (ATTENTION: Irréversible!)
./oceania destroy-all
# Confirmation requise: DESTROY-ALL
```

---

## 🔐 Gestion des Credentials

### Génération Automatique

Lors du déploiement de la stack monitoring, un mot de passe fort est automatiquement généré pour Grafana et sauvegardé dans `.oceania-credentials`.

### Afficher les Credentials

```bash
./oceania credentials
```

**Affiche** :
```
🔐 CREDENTIALS OCEANIAWATCH

Grafana:
  URL:      http://44.x.x.x:3000
  User:     admin
  Password: XyZ123AbC456DeF789GhI012

Prometheus:
  URL:      http://44.x.x.x:9090
  Auth:     None

Alertmanager:
  URL:      http://44.x.x.x:9093
  Auth:     None

Node Exporter:
  URL:      http://44.x.x.x:9100/metrics

cAdvisor:
  URL:      http://44.x.x.x:8080

Loki:
  URL:      http://44.x.x.x:3100
```

### Régénérer le Mot de Passe Grafana

```bash
./oceania credentials --regenerate
```

Génère un nouveau mot de passe fort, met à jour Grafana et sauvegarde dans `.oceania-credentials`.

### Fichier `.oceania-credentials`

**Format JSON** :
```json
{
  "generated_at": "2024-11-18T14:30:00Z",
  "instance_ip": "44.x.x.x",
  "grafana": {
    "url": "http://44.x.x.x:3000",
    "user": "admin",
    "password": "XyZ123AbC456DeF789GhI012"
  },
...
```

**Sécurité** :
- Fichier en texte clair (permissions 600)
- Ajouté au `.gitignore`
- Sauvegardé automatiquement dans `.backups/` lors des destroy
- Ne jamais commiter ce fichier

---

## 📊 Monitoring et Observabilité

### Accès aux Services

| Service | URL | Credentials | Description |
|---------|-----|-------------|-------------|
| **Grafana** | http://IP:3000 | Voir `./oceania credentials` | Dashboards et visualisation |
| **Prometheus** | http://IP:9090 | - | Métriques et requêtes PromQL |
| **Alertmanager** | http://IP:9093 | - | Gestion des alertes |
| **Node Exporter** | http://IP:9100/metrics | - | Métriques système brutes |
| **cAdvisor** | http://IP:8080 | - | Métriques conteneurs |
| **Loki** | http://IP:3100 | - | Stockage et API logs |
| **Alloy** | http://IP:12345 | - | Collecte de logs |

### Première Connexion Grafana

1. Récupérer les credentials :
   ```bash
   ./oceania credentials
   ```

2. Accéder à http://IP:3000

3. Se connecter avec les credentials affichés

4. Datasources pré-configurées :
   - Prometheus (par défaut)
   - Loki

**Note** : Le mot de passe est généré automatiquement lors du déploiement. Utilisez `./oceania credentials --regenerate` pour le changer.

### Dashboards Recommandés

4 dashboards sont automatiquement provisionnés :
- **Node Exporter - Host Metrics** : Métriques système complètes
- **Docker Containers** : Métriques conteneurs
- **Monitoring Stack Health** : Santé de la stack
- **Logs Explorer** : Exploration des logs via Loki

Pour importer des dashboards supplémentaires depuis Grafana.com :

```bash
# Dans Grafana: Menu → Dashboards → Import
# Entrer l'ID:

1860  # Node Exporter Full (métriques système complètes)
179   # Docker Container & Host Metrics
2     # Prometheus Stats (auto-monitoring)
```

### Requêtes PromQL Utiles

```promql
# CPU usage total
100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Mémoire disponible (%)
node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes * 100

# Espace disque utilisé (%)
100 - ((node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) * 100)

# Top 5 conteneurs par CPU
topk(5, rate(container_cpu_usage_seconds_total{name!=""}[5m]))

# Trafic réseau entrant
rate(node_network_receive_bytes_total[5m])
```

### Configuration des Alertes

#### Slack

```yaml
# ansible/inventory/group_vars/monitoring.yml
alertmanager_webhook_url: "https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
```

#### Microsoft Teams

Teams nécessite un adaptateur. Option recommandée : [prometheus-msteams](https://github.com/prometheus-msteams/prometheus-msteams)

```bash
# Déployer l'adaptateur (à ajouter dans docker-compose)
docker run -d -p 2000:2000 \
  -e TEAMS_INCOMING_WEBHOOK_URL="https://outlook.office.com/webhook/..." \
  quay.io/prometheusmsteams/prometheus-msteams
```

```yaml
# Dans alertmanager.yml.j2
receivers:
  - name: 'teams'
    webhook_configs:
      - url: 'http://prometheus-msteams:2000/alertmanager'
        send_resolved: true
```

#### Email (via SMTP)

Modifier `ansible/roles/monitoring-stack/templates/alertmanager.yml.j2` :

```yaml
receivers:
  - name: 'email'
    email_configs:
      - to: 'alerts@example.com'
        from: 'prometheus@example.com'
        smarthost: 'smtp.gmail.com:587'
        auth_username: 'your-email@gmail.com'
        auth_password: '{{ vault_smtp_password }}'
```

### Gestion du Monitoring

```bash
# Via script oceania
./oceania deploy-monitoring  # Déployer/Mettre à jour
./oceania status             # Voir l'état

# Via Ansible directement
cd ansible
ansible-playbook playbooks/deploy-monitoring.yml    # Déployer
ansible-playbook playbooks/validate-monitoring.yml  # Valider
ansible-playbook playbooks/stop-monitoring.yml      # Arrêter
ansible-playbook playbooks/remove-monitoring.yml    # Supprimer

# Sur le serveur
ssh -i ~/.ssh/oceania/oceania-watch-dev.pem ec2-user@IP
cd /opt/monitoring
docker compose ps                    # État des conteneurs
docker compose logs -f prometheus    # Logs Prometheus
docker compose logs -f grafana       # Logs Grafana
docker compose restart prometheus    # Redémarrer un service
```

### Recharger Configuration Prometheus

```bash
# Hot reload (sans redémarrage)
curl -X POST http://IP:9090/-/reload
```

---

## 📝 Variables de Configuration

### Backend Terraform

```hcl
# terraform/backend/terraform.tfvars
project_name      = "oceania-watch"
environment       = "dev"
aws_region        = "us-east-1"
enable_versioning = true
```

### Infrastructure

```hcl
# terraform/infrastructure/terraform.tfvars
project_name      = "oceania-watch"
environment       = "dev"
aws_region        = "us-east-1"
allowed_ssh_ips   = ["1.2.3.4/32"]  # VOTRE IP !
instance_type     = "t3.large"
root_volume_size  = 100
```

### Monitoring

```yaml
# ansible/inventory/group_vars/monitoring.yml
# Versions (utilise latest par défaut)
prometheus_version: "latest"
grafana_version: "latest"

# Credentials
grafana_admin_user: "admin"
grafana_admin_password: "{{ vault_grafana_admin_password }}"

# Rétention
prometheus_retention: "30d"
loki_retention_period: "336h"  # 14 jours

# Alertes
alertmanager_webhook_url: "https://hooks.slack.com/services/YOUR/WEBHOOK"
```

### Utiliser Ansible Vault

```bash
# Créer le fichier vault
ansible-vault create ansible/inventory/group_vars/vault.yml

# Contenu:
vault_grafana_admin_password: "SuperSecurePassword123!"

# Déployer avec vault
cd ansible
ansible-playbook playbooks/deploy-monitoring.yml --ask-vault-pass
```

---

## 🔐 Sécurité

### Fichiers Sensibles (Non Versionnés)

```bash
# Terraform
terraform/backend/terraform.tfvars
terraform/infrastructure/terraform.tfvars
terraform/infrastructure/backend.hcl
*.tfstate

# SSH
~/.ssh/oceania/*.pem
~/.ssh/oceania/*.pub

# Monitoring
ansible/inventory/group_vars/monitoring.yml
ansible/inventory/group_vars/vault.yml

# État et Credentials
.oceania-state
.oceania-credentials
.backups/
```

### Bonnes Pratiques

1. **Restreindre les IPs SSH**
   ```hcl
   # terraform/infrastructure/terraform.tfvars
   allowed_ssh_ips = ["VOTRE_IP/32"]  # Pas 0.0.0.0/0 !
   ```

3. **Utiliser Ansible Vault**
   ```bash
   ansible-vault create ansible/inventory/group_vars/vault.yml
   ```

4. **Scanner les secrets**
   ```bash
   gitleaks detect --verbose
   tfsec terraform/
   checkov -d terraform/
   ```

5. **Sauvegarder les clés SSH**
   ```bash
   cp -r ~/.ssh/oceania ~/secure-backup/
   # Puis stocker dans 1Password, Bitwarden, etc.
   ```

6. **Restreindre l'accès monitoring**
   ```hcl
   # terraform/infrastructure/network.tf
   ingress {
     description = "Grafana access"
     from_port   = 3000
     to_port     = 3000
     protocol    = "tcp"
     cidr_blocks = ["VOTRE_IP/32"]
   }
   ```

### Connexion d'Infrastructures Clientes

Pour permettre à des infrastructures externes d'envoyer leurs métriques à OceaniaWatch les clients poussent leurs métriques vers OceaniaWatch (Push avec Remote Write (Sécurisé)) :

```yaml
# Sur le client - prometheus.yml
remote_write:
  - url: "https://oceaniawatch.example.com/api/v1/write"
    basic_auth:
      username: "client_1"
      password: "secret"
```

---

## 🧪 Tests

### Tests de Connectivité

```bash
# État général
./oceania status

# SSH
ssh -i ~/.ssh/oceania/oceania-watch-dev.pem ec2-user@IP

# Ansible
cd ansible
ansible all -m ping
```

### Tests de Configuration

```bash
# Validation complète
cd ansible
ansible-playbook playbooks/validate-setup.yml
ansible-playbook playbooks/validate-monitoring.yml
```

### Tests de Monitoring

```bash
# APIs
curl http://IP:9090/-/healthy        # Prometheus
curl http://IP:3000/api/health       # Grafana
curl http://IP:9093/-/healthy        # Alertmanager

# Targets Prometheus
curl http://IP:9090/api/v1/targets | jq '.data.activeTargets[] | {job: .labels.job, health: .health}'

# Datasources Grafana
curl http://admin:password@IP:3000/api/datasources
```

### Tests de Sécurité

```bash
tfsec terraform/
gitleaks detect --verbose
checkov -d terraform/
```

---

## 💰 Coûts AWS

### Estimation Mensuelle (us-east-1)

| Ressource | Running 24/7 | Stopped | Avec Monitoring |
|-----------|--------------|---------|-----------------|
| **Instance t3.large** | ~$60 | $0 | ~$60 |
| **EBS 100GB gp3** | ~$8 | ~$8 | ~$8 |
| **Elastic IP** | $0 | $0 | $0 |
| **S3 (backend)** | <$1 | <$1 | <$1 |
| **Monitoring (CPU/RAM)** | - | - | +$0 (même instance) |
| **Monitoring (Stockage)** | - | - | +$2-5 |
| **Total** | **~$70** | **~$9** | **~$75** |

### Optimisation des Coûts

```bash
# 1. Arrêter l'instance quand inutilisée
aws ec2 stop-instances --instance-ids <ID>
# Économie: ~$60/mois

# 2. Instance plus petite (dev/staging)
instance_type = "t3.medium"  # ~$30/mois au lieu de $60

# 3. Réduire rétention monitoring
prometheus_retention: "7d"          # Au lieu de 15d
loki_retention_period: "72h"        # Au lieu de 168h

# 4. Réduire volume EBS
root_volume_size = 50  # ~$4/mois au lieu de $8

# 5. Savings Plans (prod)
# Économie: jusqu'à 72%
```

### Impact Monitoring

- **CPU** : +15-20% (modéré)
- **RAM** : +2-3 GB (modéré)
- **Disque** : +5-10 GB selon rétention (faible)
- **Réseau** : +100-200 MB/jour (négligeable)
- **Coût additionnel** : ~$5/mois (principalement stockage)

---

## 🐛 Troubleshooting

### Infrastructure

#### Terraform init échoue

```bash
# Vérifier credentials AWS
aws sts get-caller-identity

# Réinitialiser
cd terraform/infrastructure
rm -rf .terraform
terraform init -backend-config=backend.hcl -reconfigure
```

#### Instance non accessible

```bash
# Vérifier état
aws ec2 describe-instances --instance-ids <ID>

# Vérifier Security Group
# Ajouter votre IP dans allowed_ssh_ips
```

### Monitoring

#### Prometheus ne démarre pas

```bash
# Logs
docker logs prometheus

# Valider configuration
docker exec prometheus promtool check config /etc/prometheus/prometheus.yml
```

#### Grafana ne se connecte pas à Prometheus

```bash
# Connectivité réseau
docker exec grafana curl http://prometheus:9090/-/healthy

# Vérifier datasources
curl http://admin:password@IP:3000/api/datasources
```

#### Alertes non envoyées

```bash
# État Alertmanager
curl http://IP:9093/api/v1/status

# Tester alerte
curl -X POST http://IP:9093/api/v1/alerts -d '[{"labels":{"alertname":"test"}}]'
```

#### Ports déjà utilisés

```yaml
# ansible/inventory/group_vars/monitoring.yml
prometheus_port: 9091  # Au lieu de 9090
grafana_port: 3001     # Au lieu de 3000
```

### Ansible

#### Playbook échoue

```bash
# Mode verbose
ansible-playbook playbooks/deploy-monitoring.yml -vvv

# Tester connectivité
ansible all -m ping

# Vérifier inventaire
cat ansible/inventory/dev.yml
```

---

## 📁 Structure du Projet

```
OceaniaWatch/
├── oceania                          # Script principal
├── README.md                        # Ce fichier
├── .gitignore                       # Protection secrets
│
├── terraform/
│   ├── backend/                     # Backend S3 (native locking)
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── terraform.tfvars.example
│   └── infrastructure/              # Infrastructure EC2
│       ├── main.tf
│       ├── ec2.tf
│       ├── network.tf
│       ├── ssh.tf
│       ├── data.tf
│       ├── variables.tf
│       ├── outputs.tf
│       ├── terraform.tfvars.example
│       └── backend.hcl.example
│
├── ansible/
│   ├── ansible.cfg
│   ├── requirements.yml
│   ├── update-inventory.sh
│   ├── inventory/
│   │   ├── dev.yml
│   │   └── group_vars/
│   │       ├── all.yml
│   │       └── monitoring.yml.example
│   ├── playbooks/
│   │   ├── setup-instance.yml
│   │   ├── validate-setup.yml
│   │   ├── deploy-monitoring.yml
│   │   ├── validate-monitoring.yml
│   │   ├── stop-monitoring.yml
│   │   └── remove-monitoring.yml
│   └── roles/
│       ├── docker/
│       ├── common-tools/
│       ├── system-update/
│       └── monitoring-stack/
│           ├── defaults/main.yml
│           ├── tasks/main.yml
│           ├── handlers/main.yml
│           ├── templates/
│           │   ├── docker-compose.yml.j2
│           │   ├── prometheus.yml.j2
│           │   ├── alert-rules.yml.j2
│           │   ├── recording-rules.yml.j2
│           │   ├── alloy-config.alloy.j2
│           │   └── ...
│           └── files/
│               └── dashboards/
│                   ├── node-exporter.json
│                   ├── docker-containers.json
│                   ├── monitoring-health.json
│                   └── logs-explorer.json
│
├── monitoring/                          # Structure déployée sur le serveur
│   ├── docker-compose.yml               # Orchestration globale
│   ├── prometheus/
│   │   ├── docker-compose.yml
│   │   ├── prometheus.yml
│   │   └── rules/
│   │       ├── alerts.yml
│   │       └── recording.yml
│   ├── grafana/
│   │   ├── docker-compose.yml
│   │   ├── dashboards/
│   │   └── provisioning/
│   ├── alertmanager/
│   │   └── docker-compose.yml
│   ├── node-exporter/
│   │   └── docker-compose.yml
│   ├── cadvisor/
│   │   └── docker-compose.yml
│   ├── loki/
│   │   └── docker-compose.yml
│   └── alloy/
│       ├── docker-compose.yml
│       └── alloy-config.alloy
│
└── .backups/                        # Sauvegardes automatiques
```

---

## 🔗 Ressources

### Documentation

- [Terraform](https://developer.hashicorp.com/terraform/docs)
- [Ansible](https://docs.ansible.com/)
- [Prometheus](https://prometheus.io/docs/)
- [Grafana](https://grafana.com/docs/)
- [Docker Compose](https://docs.docker.com/compose/)

### Dashboards Grafana

- [Node Exporter Full (1860)](https://grafana.com/grafana/dashboards/1860)
- [Docker Container & Host (179)](https://grafana.com/grafana/dashboards/179)
- [Prometheus Stats (2)](https://grafana.com/grafana/dashboards/2)

---

## 📜 Changelog

### Version 2.1.0 (2026-01-30)

**Ajouté** :
- ✅ 4 dashboards Grafana pré-configurés (Node, Docker, Health, Logs)
- ✅ 15 alertes supplémentaires (Disk I/O, Network, Container restarts)
- ✅ 16 recording rules Prometheus pour optimiser les requêtes
- ✅ Grafana Alloy pour la collecte de logs (remplace Promtail deprecated)
- ✅ Datasource UIDs pour compatibilité dashboards

**Modifié** :
- 🔄 Migration Promtail → Alloy (Promtail EOL Mars 2026)

### Version 2.0.0 (2024-11-18)

**Ajouté** :
- ✅ Stack monitoring complète (Prometheus, Grafana, Alertmanager, etc.)
- ✅ Rôle Ansible `monitoring-stack` modulaire
- ✅ 4 playbooks de gestion du monitoring
- ✅ Commandes `deploy-all`, `deploy-infra`, `deploy-monitoring`
- ✅ Alertes pré-configurées (CPU, RAM, Disk, Containers)
- ✅ Dashboards Grafana auto-provisionnés
- ✅ Documentation complète intégrée

**Modifié** :
- 🔄 Script `oceania` refactorisé (3 modes de déploiement)
- 🔄 Flux de déploiement en 4 étapes
- 🔄 Commande `status` avec état du monitoring

### Version 0.1.0 (2024-11-18)

- ✅ Infrastructure de base (Terraform + Ansible)
- ✅ Backend S3 avec native locking
- ✅ Instance EC2 avec Docker
- ✅ Script `oceania` initial

---

## 📄 Licence

MIT

---

## 👥 Auteurs

Maxime GIQUEL  
contact.lr8gr@aleeas.com

---

## 🎯 Prochaines Étapes

### Court Terme
1. ✅ Dashboards Grafana pré-configurés
2. ✅ Alertes avancées (15 règles)
3. ✅ Recording rules Prometheus
4. ✅ Collecte de logs avec Alloy
5. 🔄 Configurer webhooks Alertmanager
6. 🔄 Restreindre accès réseau

### Moyen Terme
1. 🔄 Ajouter Grafana Tempo (tracing)
2. 🔄 Intégrer AWS CloudWatch
3. 🔄 Reverse proxy (Traefik/Nginx)
4. 🔄 HTTPS avec Let's Encrypt

### Long Terme
1. 🚀 Gestion des alertes de N1 via IA.2
2. 🚀 Authentification externe (LDAP, OAuth)
3. 🚀 Multi-région
4. 🚀 Auto Scaling Group + ALB
5. 🚀 Kubernetes (EKS)
6. 🚀 GitOps (ArgoCD/Flux)


---

**Dernière mise à jour** : 30 Janvier 2026  
**Version** : 2.1.0  
**Statut** : Production Ready ✅
