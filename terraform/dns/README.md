# Module Terraform DNS - Route 53

Ce module Terraform gère la configuration DNS pour OceaniaWatch via AWS Route 53.

## Architecture DNS

```
twca.cloud (zone hébergée Route 53)
└── oceania.twca.cloud (A record → IP EC2)
    ├── grafana.oceania.twca.cloud (CNAME → oceania.twca.cloud)
    ├── prometheus.oceania.twca.cloud (CNAME → oceania.twca.cloud)
    ├── alertmanager.oceania.twca.cloud (CNAME → oceania.twca.cloud)
    ├── loki.oceania.twca.cloud (CNAME → oceania.twca.cloud)
    ├── traefik.oceania.twca.cloud (CNAME → oceania.twca.cloud)
    ├── cadvisor.oceania.twca.cloud (CNAME → oceania.twca.cloud)
    └── *.oceania.twca.cloud (CNAME → oceania.twca.cloud) [wildcard]
```

## Fonctionnalités

- ✅ Gestion de zone Route 53 (création ou utilisation existante)
- ✅ Enregistrement A pour le domaine de base (`oceania.twca.cloud`)
- ✅ Enregistrements CNAME pour chaque service
- ✅ Wildcard CNAME pour sous-domaines non définis
- ✅ TTL configurable (défaut: 300 secondes)
- ✅ Export JSON pour Ansible

## Variables

### Obligatoires

| Variable | Type | Description |
|----------|------|-------------|
| `instance_public_ip` | string | IP publique de l'instance EC2 |
| `project_name` | string | Nom du projet |
| `environment` | string | Environnement (Dev/Staging/Qual/Prod) |

### Optionnelles

| Variable | Type | Défaut | Description |
|----------|------|--------|-------------|
| `domain_name` | string | `"twca.cloud"` | Domaine principal |
| `region_suffix` | string | `"oceania"` | Suffixe régional |
| `subdomains` | list(string) | `["grafana", "prometheus", ...]` | Liste des services |
| `ttl` | number | `300` | TTL des enregistrements DNS |
| `create_zone` | bool | `false` | Créer la zone Route53 (si zone existe déjà) |
| `zone_id` | string | `""` | ID zone existante (si `create_zone = false`) |

## Outputs

| Output | Description |
|--------|-------------|
| `zone_id` | ID de la zone Route 53 |
| `zone_name` | Nom de la zone |
| `nameservers` | Nameservers à configurer chez le registrar |
| `base_domain` | Domaine de base (`oceania.twca.cloud`) |
| `service_fqdns` | Map des FQDNs par service |
| `all_fqdns` | Liste complète des FQDNs |
| `dns_config` | Configuration JSON pour Ansible |

## Utilisation

### 1. Configuration avec zone existante (recommandé)

```hcl
module "dns" {
  source = "../dns"

  # Référence zone existante
  create_zone = false
  zone_id     = "Z0123456789ABCDEFGHIJ"  # ID de twca.cloud

  # Configuration
  domain_name        = "twca.cloud"
  region_suffix      = "oceania"
  instance_public_ip = aws_eip.main.public_ip

  # Métadonnées
  project_name = var.project_name
  environment  = var.environment

  # Services à exposer
  subdomains = [
    "grafana",
    "prometheus",
    "alertmanager",
    "loki",
    "traefik",
    "cadvisor"
  ]
}
```

### 2. Configuration avec création de zone

```hcl
module "dns" {
  source = "../dns"

  # Créer la zone
  create_zone = true

  # Configuration
  domain_name        = "twca.cloud"
  region_suffix      = "oceania"
  instance_public_ip = aws_eip.main.public_ip

  project_name = var.project_name
  environment  = var.environment
}
```

### 3. Export pour Ansible

```bash
# Exporter la config DNS pour Ansible
terraform output -json dns_config > ../../ansible/group_vars/dns_config.json
```

## Ajout de nouveaux services

Pour ajouter un nouveau service (ex: `nodeexporter`) :

1. Modifier la variable `subdomains` :

```hcl
subdomains = [
  "grafana",
  "prometheus",
  "alertmanager",
  "loki",
  "traefik",
  "cadvisor",
  "nodeexporter"  # Nouveau
]
```

2. Appliquer les modifications :

```bash
terraform plan
terraform apply
```

Le CNAME `nodeexporter.oceania.twca.cloud` sera créé automatiquement.

## Configuration du Registrar

Après le premier déploiement, configurer les nameservers chez le registrar :

```bash
# Récupérer les nameservers
terraform output nameservers
```

Exemple de sortie :
```
[
  "ns-1234.awsdns-12.org",
  "ns-5678.awsdns-34.com",
  "ns-9012.awsdns-56.net",
  "ns-3456.awsdns-78.co.uk"
]
```

Configurer ces 4 nameservers chez votre registrar (ex: Namecheap, GoDaddy).

## Tests DNS

```bash
# Test résolution A record (base)
dig oceania.twca.cloud

# Test résolution CNAME (service)
dig grafana.oceania.twca.cloud

# Test wildcard
dig random.oceania.twca.cloud

# Test avec nameserver spécifique
dig @ns-1234.awsdns-12.org oceania.twca.cloud
```

## Sécurité

- ✅ Validation des entrées (regex sur domaines/IPs)
- ✅ TTL limité entre 60-86400 secondes
- ✅ Tags pour tracking et compliance
- ⚠️ **Important** : Ce module ne crée PAS de politique IAM Route53 pour Traefik (géré dans le module `infrastructure`)

## Dépannage

### Problème : Zone déjà existante

**Erreur** : `Error creating Route53 Hosted Zone: EntityAlreadyExists`

**Solution** : Utiliser `create_zone = false` et spécifier `zone_id`

```hcl
create_zone = false
zone_id     = "Z0123456789ABCDEFGHIJ"
```

### Problème : IP invalide

**Erreur** : `Must be a valid IPv4 address`

**Solution** : Vérifier que `instance_public_ip` est bien une IP (pas un hostname)

```hcl
# ✅ Correct
instance_public_ip = "54.123.45.67"

# ❌ Incorrect
instance_public_ip = "ec2-54-123-45-67.compute-1.amazonaws.com"
```

### Problème : DNS ne résout pas

**Causes possibles** :
1. Nameservers pas configurés chez le registrar (attendre 24-48h propagation)
2. TTL cache (attendre expiration)
3. Zone ID incorrect (si `create_zone = false`)

**Debug** :
```bash
# Vérifier nameservers actuels
dig +short NS twca.cloud

# Vérifier configuration Route53
aws route53 get-hosted-zone --id Z0123456789ABCDEFGHIJ
```

## Coûts AWS

| Ressource | Coût mensuel estimé |
|-----------|---------------------|
| Hosted Zone Route 53 | $0.50/zone |
| DNS Queries (1M/mois) | $0.40 |
| **Total** | **~$1/mois** |

---

**Version** : 1.0.0
**Dernière mise à jour** : 2024-11-19
