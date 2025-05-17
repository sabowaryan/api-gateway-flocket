# API Gateway Flocket

Ce projet contient la configuration de l'API Gateway Flocket basé sur Kong.

## Structure du projet

```
.
├── config/
│   ├── services.yaml          # Définition des services backend
│   ├── routes.yaml            # Mapping des URL publiques
│   └── plugins/               # Configurations des plugins
├── scripts/
│   ├── apply-config.sh        # Script d'application des configurations
│   ├── generate-certs.sh      # Script de génération des certificats
│   └── backup-config.sh       # Script de sauvegarde
├── certs/                     # Certificats SSL
├── manifests/                 # Manifests Kubernetes
├── logs/                      # Logs (optionnel)
├── kong.conf                  # Configuration principale
├── docker-compose.yml         # Orchestration locale
└── README.md                  # Documentation
```

## Prérequis

- Docker et Docker Compose
- Kubernetes (pour le déploiement en production)
- OpenSSL (pour la génération des certificats)
- kubectl (pour le déploiement Kubernetes)

## Installation

### Développement local

1. Générer les certificats SSL :
```bash
./scripts/generate-certs.sh
```

2. Démarrer les services :
```bash
docker-compose up -d
```

3. Vérifier le statut :
```bash
docker-compose ps
```

### Déploiement Kubernetes

1. Créer le namespace :
```bash
kubectl apply -f manifests/namespace.yaml
```

2. Appliquer les configurations :
```bash
./scripts/apply-config.sh
```

3. Vérifier le déploiement :
```bash
kubectl get pods -n flocket
```

## Configuration

### Services

Les services sont définis dans `config/services.yaml`. Chaque service doit avoir :
- Un nom unique
- Une URL de destination
- Des routes associées

### Routes

Les routes sont définies dans `config/routes.yaml`. Chaque route doit avoir :
- Un nom unique
- Un chemin d'accès
- Un service associé

### Plugins

Les plugins sont configurés dans `config/plugins/`. Les plugins disponibles sont :
- JWT : Authentification
- Rate Limiting : Limitation de débit
- CORS : Gestion des requêtes cross-origin
- HTTP Log : Journalisation
- Prometheus : Monitoring

## Maintenance

### Sauvegarde

Pour sauvegarder la configuration :
```bash
./scripts/backup-config.sh
```

### Renouvellement des certificats

Pour renouveler les certificats SSL :
```bash
./scripts/generate-certs.sh
```

## Monitoring

L'API Gateway expose des métriques Prometheus sur le port 8001 :
```bash
curl http://localhost:8001/metrics
```

## Sécurité

- Les certificats SSL sont stockés dans `certs/`
- Les secrets sont gérés via Kubernetes
- L'accès à l'API Admin est restreint

## Support

Pour toute question ou problème, veuillez contacter l'équipe Flocket. 