# Rôle Ansible - Traefik

Ce rôle Ansible déploie Traefik v3.6.2 comme reverse proxy HTTPS avec Let's Encrypt (DNS Challenge Route53).

## Fonctionnalités

- ✅ Traefik v3.6.2 via Docker Compose
- ✅ Let's Encrypt avec DNS challenge Route 53 (wildcard `*.oceania.twca.cloud`)
- ✅ Découverte automatique des conteneurs Docker
- ✅ Dashboard sécurisé (BasicAuth)
- ✅ Redirection HTTP → HTTPS automatique
- ✅ Security headers (HSTS, XSS Protection, etc.)
- ✅ Configuration statique + dynamique
- ✅ Connexion au network monitoring existant

## Prérequis

1. **Module DNS Terraform déployé** (zone Route53 + enregistrements)
2. **Stack monitoring déployée** (Prometheus, Grafana, etc.)
3. **IAM Role EC2 avec permissions Route53** (DNS Challenge)
4. **Docker et Docker Compose installés** (rôle `docker`)

## Variables

### Obligatoires (depuis Terraform DNS output)

Ces variables sont automatiquement récupérées depuis `dns_config.json` :

```yaml
dns_config:
  zone_id: "Z0123456789ABCDEFGHIJ"
  zone_name: "twca.cloud"
  base_domain: "oceania.twca.cloud"
  aws_region: "us-east-1"
```

### Optionnelles (defaults/main.yml)

| Variable | Défaut | Description |
|----------|--------|-------------|
| `traefik_version` | `"v3.6.2"` | Version Traefik |
| `traefik_http_port` | `80` | Port HTTP |
| `traefik_https_port` | `443` | Port HTTPS |
| `traefik_dashboard_port` | `8080` | Port dashboard |
| `traefik_acme_email` | `"dns.oceania@gnrs.ca"` | Email Let's Encrypt |
| `traefik_use_staging_ca` | `false` | Utiliser staging CA (tests) |
| `traefik_dashboard_enabled` | `true` | Activer dashboard |
| `traefik_dashboard_auth_user` | `"admin"` | Utilisateur dashboard |
| `traefik_log_level` | `"INFO"` | Niveau de logs |

### Services exposés

Par défaut, ces services sont exposés via HTTPS :

```yaml
traefik_services:
  - name: "grafana"
    subdomain: "grafana"
    container_name: "grafana"
    port: 3000
  - name: "prometheus"
    subdomain: "prometheus"
    container_name: "prometheus"
    port: 9090
  - name: "alertmanager"
    subdomain: "alertmanager"
    container_name: "alertmanager"
    port: 9093
  - name: "loki"
    subdomain: "loki"
    container_name: "loki"
    port: 3100
  - name: "cadvisor"
    subdomain: "cadvisor"
    container_name: "cadvisor"
    port: 8080
```

## Utilisation

### Déploiement

```bash
cd ansible
ansible-playbook -i inventory/dev.yml playbooks/deploy-traefik.yml
```

### Ajout d'un nouveau service

1. **Modifier `defaults/main.yml`** :

```yaml
traefik_services:
  - name: "nodeexporter"
    subdomain: "nodeexporter"
    container_name: "node-exporter"
    port: 9100
```

2. **Ajouter le sous-domaine DNS** (Terraform) :

```hcl
dns_subdomains = [
  # ...
  "nodeexporter"
]
```

3. **Redéployer** :

```bash
terraform apply
ansible-playbook -i inventory/dev.yml playbooks/deploy-traefik.yml
```

Le service sera automatiquement exposé via `https://nodeexporter.oceania.twca.cloud`.

## Accès aux services

### Dashboard Traefik

- **HTTP** : `http://<IP>:8080/dashboard/`
- **HTTPS** : `https://traefik.oceania.twca.cloud/dashboard/`
- **Credentials** : `admin / changeme`

### Services monitoring

| Service | URL HTTPS |
|---------|-----------|
| Grafana | `https://grafana.oceania.twca.cloud` |
| Prometheus | `https://prometheus.oceania.twca.cloud` |
| Alertmanager | `https://alertmanager.oceania.twca.cloud` |
| Loki | `https://loki.oceania.twca.cloud` |
| cAdvisor | `https://cadvisor.oceania.twca.cloud` |

## Configuration avancée

### Changer le mot de passe dashboard

1. **Générer le hash bcrypt** :

```bash
# Méthode 1 : htpasswd
htpasswd -nb admin monNouveauMotDePasse | sed -e s/\\$/\\$\\$/g

# Méthode 2 : Python
python3 -c 'import bcrypt; print("admin:" + bcrypt.hashpw(b"monNouveauMotDePasse", bcrypt.gensalt()).decode())'
```

2. **Copier le hash dans `defaults/main.yml`** :

```yaml
traefik_dashboard_auth_password_hash: "admin:$$2y$$05$$..."
```

3. **Redéployer** :

```bash
ansible-playbook -i inventory/dev.yml playbooks/deploy-traefik.yml --tags traefik
```

### Utiliser Let's Encrypt staging (tests)

Pour éviter les rate limits lors des tests :

```yaml
traefik_use_staging_ca: true
```

⚠️ **Certificats staging non reconnus par les navigateurs** (erreur SSL attendue).

### Désactiver le dashboard

```yaml
traefik_dashboard_enabled: false
```

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         Internet                             │
└──────────────┬──────────────────────────────────────────────┘
               │ HTTPS (443) / HTTP (80)
               ▼
┌─────────────────────────────────────────────────────────────┐
│  Traefik Reverse Proxy                                      │
│  - Let's Encrypt (DNS Challenge Route53)                    │
│  - Wildcard *.oceania.twca.cloud                            │
│  - Auto-discovery Docker labels                             │
└──────────┬──────────────────────────────────────────────────┘
           │ traefik-network
           ▼
┌─────────────────────────────────────────────────────────────┐
│  Services Monitoring (Docker Containers)                    │
│  ├─ Grafana (3000)                                          │
│  ├─ Prometheus (9090)                                       │
│  ├─ Alertmanager (9093)                                     │
│  ├─ Loki (3100)                                             │
│  └─ cAdvisor (8080)                                         │
└─────────────────────────────────────────────────────────────┘
```

## Sécurité

### Certificats SSL

- **Storage** : `/opt/traefik/letsencrypt/acme.json` (permissions `600`)
- **Renouvellement** : Automatique (Traefik)
- **Wildcard** : `*.oceania.twca.cloud`
- **Provider** : Let's Encrypt (DNS Challenge Route53)

### Dashboard

- **BasicAuth** : Activé par défaut
- **Credentials** : `admin / changeme` (⚠️ **CHANGER EN PRODUCTION**)
- **Accès** : Interne (localhost:8080) + HTTPS externe

### IAM Permissions

Le rôle EC2 doit avoir ces permissions Route53 :

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["route53:GetChange"],
      "Resource": "arn:aws:route53:::change/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "route53:ChangeResourceRecordSets",
        "route53:ListResourceRecordSets"
      ],
      "Resource": "arn:aws:route53:::hostedzone/<ZONE_ID>"
    },
    {
      "Effect": "Allow",
      "Action": ["route53:ListHostedZonesByName"],
      "Resource": "*"
    }
  ]
}
```

Ces permissions sont automatiquement créées par le module Terraform `infrastructure/iam.tf`.

## Dépannage

### Problème : Certificat Let's Encrypt non généré

**Symptômes** : `ERR_CERT_AUTHORITY_INVALID` ou `NET::ERR_CERT_DATE_INVALID`

**Solutions** :

1. **Vérifier les logs Traefik** :

```bash
docker logs traefik
```

2. **Vérifier les permissions IAM Route53** :

```bash
# Sur l'EC2
curl http://169.254.169.254/latest/meta-data/iam/security-credentials/
```

3. **Vérifier la résolution DNS** :

```bash
dig grafana.oceania.twca.cloud
```

4. **Forcer la régénération** :

```bash
# Supprimer acme.json et redémarrer
sudo rm /opt/traefik/letsencrypt/acme.json
sudo touch /opt/traefik/letsencrypt/acme.json
sudo chmod 600 /opt/traefik/letsencrypt/acme.json
docker compose -f /opt/traefik/docker-compose.yml restart
```

### Problème : Dashboard inaccessible

**Vérifications** :

```bash
# Port 8080 ouvert ?
sudo netstat -tlnp | grep 8080

# Traefik en cours ?
docker ps | grep traefik

# Logs
docker logs traefik | grep dashboard
```

### Problème : Service non routé

**Vérifications** :

1. **Container connecté au network `traefik-network`** :

```bash
docker inspect <container> | grep -A 10 Networks
```

2. **Labels Traefik présents** (config dynamique) :

```bash
cat /opt/traefik/dynamic/dynamic.yml | grep <service>
```

3. **Dashboard Traefik → HTTP → Routers** :

`http://localhost:8080/dashboard/#/http/routers`

## Fichiers générés

```
/opt/traefik/
├── docker-compose.yml           # Docker Compose Traefik
├── traefik.yml                  # Configuration statique
├── dynamic/
│   └── dynamic.yml              # Configuration dynamique (routing)
└── letsencrypt/
    └── acme.json                # Certificats Let's Encrypt (600)
```

## Logs

```bash
# Logs Traefik
docker logs -f traefik

# Logs JSON formatés
docker logs traefik | jq .

# Filtrer erreurs
docker logs traefik 2>&1 | grep -i error
```

---

**Version** : 1.0.0
**Dernière mise à jour** : 2024-11-19
**Traefik** : v3.6.2
