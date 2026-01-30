# Monitoring Stack Role

Role Ansible pour déployer une stack de monitoring complète avec Prometheus, Grafana, Loki, Alertmanager, Node Exporter et cAdvisor.

## 📊 Stack de Monitoring

### Services déployés

| Service | Image | Port | Description |
|---------|-------|------|-------------|
| **Prometheus** | `prom/prometheus:latest` | 9090 | Collecte et stockage des métriques |
| **Grafana** | `grafana/grafana:latest` | 3000 | Visualisation et dashboards |
| **Alertmanager** | `prom/alertmanager:latest` | 9093 | Gestion des alertes |
| **Node Exporter** | `prom/node-exporter:latest` | 9100 | Métriques système (CPU, RAM, Disk) |
| **cAdvisor** | `gcr.io/cadvisor/cadvisor:latest` | 8080 | Métriques conteneurs Docker |
| **Loki** | `grafana/loki:latest` | 3100 | Collecte et stockage des logs |

### Versions actuelles (tag `latest`)

> **Note**: Les versions sont automatiquement mises à jour lors du déploiement.
> Consultez `/opt/monitoring/versions.txt` sur le serveur pour les versions déployées.

**Dernière vérification**: 2026-01-30

- **Prometheus**: v3.x
- **Grafana**: v12.x
- **Alertmanager**: v0.29.x
- **Node Exporter**: v1.10.x
- **cAdvisor**: v0.53.x
- **Loki**: v3.5.x

## 🚀 Utilisation

### Déploiement

```bash
ansible-playbook playbooks/setup-monitoring.yml
```

### Accès aux services

Après déploiement, les services sont accessibles via :

```
http://<instance-ip>:3000   - Grafana (admin/changeme)
http://<instance-ip>:9090   - Prometheus
http://<instance-ip>:9093   - Alertmanager
http://<instance-ip>:9100   - Node Exporter metrics
http://<instance-ip>:8080   - cAdvisor metrics
http://<instance-ip>:3100   - Loki
```

### Vérifier les versions déployées

```bash
# Sur le serveur
cat /opt/monitoring/versions.txt

# Ou via Ansible
ansible oceania-dev -m shell -a "cat /opt/monitoring/versions.txt"
```

## ⚙️ Configuration

### Variables par défaut

Voir `defaults/main.yml` pour toutes les variables configurables.

**Principales variables** :

```yaml
# Versions (utilise latest par défaut)
prometheus_version: "latest"
grafana_version: "latest"
alertmanager_version: "latest"

# Ports
prometheus_port: 9090
grafana_port: 3000
alertmanager_port: 9093

# Grafana admin
grafana_admin_user: "admin"
grafana_admin_password: "changeme"  # À changer !

# Rétention des données
prometheus_retention: "15d"
loki_retention_period: "168h"  # 7 jours
```

### Surcharger les variables

Créer un fichier `group_vars/oceania.yml` :

```yaml
grafana_admin_password: "super-secret-password"
prometheus_retention: "30d"
```

## 📁 Structure des fichiers

```
/opt/monitoring/
├── docker-compose.yml          # Compose principal
├── versions.txt                # Versions déployées
├── prometheus/
│   ├── docker-compose.yml
│   ├── prometheus.yml         # Configuration Prometheus
│   └── rules/
│       └── alerts.yml         # Règles d'alertes
├── grafana/
│   ├── docker-compose.yml
│   └── provisioning/
│       ├── datasources/
│       │   └── datasource.yml  # Prometheus + Loki datasources
│       └── dashboards/
│           └── dashboards.yml
├── alertmanager/
│   ├── docker-compose.yml
│   └── alertmanager.yml       # Configuration alertes
├── loki/
│   ├── docker-compose.yml
│   └── loki-config.yml
├── node-exporter/
│   └── docker-compose.yml
└── cadvisor/
    └── docker-compose.yml
```

## 🔔 Alertes configurées

### Alertes critiques
- **InstanceDown** : Instance arrêtée pendant 5min
- **ContainerDown** : Conteneur Docker arrêté pendant 5min

### Alertes warning
- **HighCPUUsage** : CPU > 80% pendant 10min
- **HighMemoryUsage** : RAM > 85% pendant 10min
- **DiskSpaceLow** : Disk < 15% pendant 5min

## 🎨 Dashboards Grafana

Les dashboards sont automatiquement provisionnés :

1. **Node Exporter Full** : Métriques système complètes
2. **Docker Container Monitoring** : Métriques conteneurs
3. **Prometheus Stats** : Statistiques Prometheus

## 🔧 Maintenance

### Mettre à jour la stack

```bash
# Sur le serveur
cd /opt/monitoring
docker compose pull
docker compose up -d
```

### Redémarrer un service

```bash
docker compose restart prometheus
docker compose restart grafana
```

### Voir les logs

```bash
docker compose logs -f prometheus
docker compose logs -f grafana
```

### Sauvegarder les données

```bash
# Volumes Docker
docker volume ls | grep monitoring

# Backup Grafana dashboards
docker cp grafana:/var/lib/grafana/grafana.db ./grafana-backup.db

# Backup Prometheus data
docker cp prometheus:/prometheus ./prometheus-backup/
```

## 🐛 Troubleshooting

### Prometheus ne démarre pas

```bash
# Vérifier la configuration
docker compose exec prometheus promtool check config /etc/prometheus/prometheus.yml

# Voir les logs
docker compose logs prometheus
```

### Grafana ne se connecte pas à Prometheus

```bash
# Tester la connectivité
docker compose exec grafana curl http://prometheus:9090/-/healthy

# Vérifier les datasources
docker compose exec grafana cat /etc/grafana/provisioning/datasources/datasource.yml
```

### Alertes ne fonctionnent pas

```bash
# Vérifier les règles
docker compose exec prometheus promtool check rules /etc/prometheus/rules/alerts.yml

# Vérifier Alertmanager
curl http://localhost:9093/-/healthy
```

## 📚 Documentation

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/grafana/latest/)
- [Loki Documentation](https://grafana.com/docs/loki/latest/)
- [Alertmanager Documentation](https://prometheus.io/docs/alerting/latest/alertmanager/)

## 🔐 Sécurité

**⚠️ IMPORTANT pour production** :

1. Changer le mot de passe Grafana :
   ```yaml
   grafana_admin_password: "votre-mot-de-passe-fort"
   ```

2. Activer HTTPS (via reverse proxy Nginx/Traefik)

3. Configurer l'authentification externe (LDAP, OAuth)

4. Restreindre les ports réseau (via Security Group AWS)

5. Utiliser Ansible Vault pour les secrets :
   ```bash
   ansible-vault encrypt_string 'mon-secret' --name 'grafana_admin_password'
   ```

## 📝 Changelog

### v1.0.0 (Novembre 2024)
- Initial release
- Prometheus + Grafana + Loki + Alertmanager
- Node Exporter + cAdvisor
- Auto-provisioning datasources
- Alertes de base configurées
- **Prometheus**: latest
- **Grafana**: latest
- **Alertmanager**: latest
- **Node Exporter**: latest
- **cAdvisor**: latest
- **Loki**: latest
