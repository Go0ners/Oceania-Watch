# Rôle Ansible - CoreDNS

Ce rôle Ansible déploie CoreDNS comme serveur DNS local pour résoudre les sous-domaines `*.oceania.twca.cloud` et `*.local`.

## Fonctionnalités

- ✅ CoreDNS via Docker Compose
- ✅ Résolution DNS locale pour `*.oceania.twca.cloud`
- ✅ Résolution DNS locale pour `*.local` (conteneurs)
- ✅ Fallback vers DNS publics (1.1.1.1, 8.8.8.8)
- ✅ Cache DNS (30 secondes TTL)
- ✅ Logs structurés

## Prérequis

1. **Rôle Traefik déployé** (Traefik doit être en cours d'exécution)
2. **Network `traefik-network` créé**
3. **Docker et Docker Compose installés**

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  Application / Conteneur Docker                             │
│  ├─ DNS Query: grafana.oceania.twca.cloud                   │
│  └─ DNS Query: grafana.local                                │
└──────────────┬──────────────────────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────────────────────┐
│  CoreDNS (localhost:53)                                     │
│  ├─ Zone: oceania.twca.cloud                                │
│  │  └─ Hosts: grafana → <IP_EC2>                            │
│  ├─ Zone: *.local                                           │
│  │  └─ Hosts: grafana.local → <IP_EC2>                      │
│  └─ Catch-all: Forward to 1.1.1.1, 8.8.8.8                  │
└──────────────┬──────────────────────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────────────────────┐
│  DNS Public (Cloudflare / Google DNS)                       │
└─────────────────────────────────────────────────────────────┘
```

## Variables

### Optionnelles (defaults/main.yml)

| Variable | Défaut | Description |
|----------|--------|-------------|
| `coredns_version` | `"latest"` | Version CoreDNS |
| `coredns_port_udp` | `53` | Port UDP |
| `coredns_port_tcp` | `53` | Port TCP |
| `coredns_domain` | `"oceania.twca.cloud"` | Zone DNS principale |
| `coredns_upstream_dns` | `["1.1.1.1:53", "8.8.8.8:53"]` | DNS fallback |
| `coredns_cache_ttl` | `30` | TTL cache (secondes) |

### Services par défaut

```yaml
coredns_local_services:
  - name: "grafana"
    ip: "<IP_EC2>"
  - name: "prometheus"
    ip: "<IP_EC2>"
  - name: "alertmanager"
    ip: "<IP_EC2>"
  - name: "loki"
    ip: "<IP_EC2>"
  - name: "traefik"
    ip: "<IP_EC2>"
  - name: "cadvisor"
    ip: "<IP_EC2>"
```

## Utilisation

### Déploiement

```bash
cd ansible
ansible-playbook -i inventory/dev.yml playbooks/deploy-traefik.yml
```

CoreDNS est déployé automatiquement avec le playbook `deploy-traefik.yml`.

### Tests de résolution DNS

```bash
# Tester résolution locale
dig @localhost oceania.twca.cloud
dig @localhost grafana.oceania.twca.cloud

# Tester résolution .local
dig @localhost grafana.local

# Tester fallback DNS public
dig @localhost google.com
```

### Configurer Docker pour utiliser CoreDNS

**Méthode 1 : Via daemon.json (global)**

```bash
sudo tee /etc/docker/daemon.json <<EOF
{
  "dns": ["172.17.0.1", "1.1.1.1"]
}
EOF

sudo systemctl restart docker
```

**Méthode 2 : Via Docker Compose (par service)**

```yaml
services:
  mon-app:
    image: mon-image
    dns:
      - 172.17.0.1  # Docker bridge IP (CoreDNS)
      - 1.1.1.1
```

## Ajout d'un nouveau service

1. **Modifier `defaults/main.yml`** :

```yaml
coredns_local_services:
  - name: "nodeexporter"
    ip: "{{ coredns_traefik_ip }}"
```

2. **Redéployer** :

```bash
ansible-playbook -i inventory/dev.yml playbooks/deploy-traefik.yml --tags coredns
```

Le service sera résolvable via :
- `nodeexporter.oceania.twca.cloud` → `<IP_EC2>`
- `nodeexporter.local` → `<IP_EC2>`

## Corefile généré

```corefile
# Zone oceania.twca.cloud
oceania.twca.cloud {
    log
    errors
    hosts {
        <IP_EC2> oceania.twca.cloud
        <IP_EC2> grafana.oceania.twca.cloud
        <IP_EC2> prometheus.oceania.twca.cloud
        ...
        fallthrough
    }
    forward . 1.1.1.1:53 8.8.8.8:53
    cache 30
}

# Zone .local
*.local {
    log
    errors
    hosts {
        <IP_EC2> grafana.local
        <IP_EC2> prometheus.local
        ...
        fallthrough
    }
    cache 30
}

# Catch-all
. {
    log
    errors
    forward . 1.1.1.1:53 8.8.8.8:53
    cache 30
}
```

## Dépannage

### Problème : CoreDNS ne démarre pas

**Vérifications** :

```bash
# Port 53 déjà utilisé ?
sudo netstat -tlnp | grep :53

# Logs CoreDNS
docker logs coredns
```

**Solution** : Stopper systemd-resolved (Amazon Linux 2023 n'a pas systemd-resolved par défaut)

```bash
# Si systemd-resolved est actif
sudo systemctl stop systemd-resolved
sudo systemctl disable systemd-resolved
```

### Problème : Résolution DNS ne fonctionne pas

**Tests** :

```bash
# CoreDNS répond ?
dig @localhost oceania.twca.cloud

# Corefile correct ?
cat /opt/coredns/Corefile

# Logs
docker logs coredns | grep -i error
```

### Problème : Conteneurs ne résolvent pas via CoreDNS

**Solution** : Configurer Docker DNS (voir ci-dessus)

```bash
# Vérifier config Docker
cat /etc/docker/daemon.json

# Tester depuis un conteneur
docker run --rm alpine ping -c 1 grafana.local
```

## Fichiers générés

```
/opt/coredns/
├── docker-compose.yml    # Docker Compose CoreDNS
└── Corefile              # Configuration CoreDNS
```

## Logs

```bash
# Logs CoreDNS
docker logs -f coredns

# Logs filtrés (queries)
docker logs coredns 2>&1 | grep -i query

# Logs filtrés (erreurs)
docker logs coredns 2>&1 | grep -i error
```

## Limitations

- **Port 53 privilégié** : CoreDNS écoute sur port 53 (root), nécessite Docker avec privileges
- **Pas de DNSSEC** : CoreDNS ne valide pas DNSSEC dans cette configuration
- **Cache simple** : TTL court (30s) pour éviter stale records

## Sécurité

- ✅ CoreDNS read-only (Corefile monté en `:ro`)
- ✅ Pas d'exposition externe (localhost:53 seulement)
- ✅ Fallback vers DNS publics sécurisés (Cloudflare, Google)
- ⚠️ Pas de filtering/blacklist (à ajouter si nécessaire)

---

**Version** : 1.0.0
**Dernière mise à jour** : 2024-11-19
**CoreDNS** : latest
