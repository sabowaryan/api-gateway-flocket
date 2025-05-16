# API Gateway Flocket

Cette API Gateway est basée sur Kong et déployée dans un environnement Kubernetes pour le réseau social Flocket.

## Structure des Dossiers

- `config/` : Fichiers de configuration pour Kong
- `scripts/` : Scripts d'automatisation pour le déploiement et la maintenance
- `certs/` : Certificats SSL pour sécuriser les communications
- `manifests/` : Fichiers YAML pour le déploiement Kubernetes
- `logs/` : Répertoire pour les logs locaux

## Prérequis

- Kubernetes cluster opérationnel
- kubectl configuré pour accéder au cluster
- Helm (optionnel, pour une installation simplifiée)

## Installation

### Méthode 1: Déploiement avec kubectl

```bash
# Appliquer les configurations Kubernetes
kubectl apply -f manifests/namespace.yaml
kubectl apply -f manifests/postgres.yaml
kubectl apply -f manifests/kong-config.yaml
kubectl apply -f manifests/kong-deployment.yaml
kubectl apply -f manifests/kong-service.yaml
kubectl apply -f manifests/kong-ingress.yaml
```

### Méthode 2: Déploiement avec Helm

```bash
# Ajouter le repo Helm de Kong
helm repo add kong https://charts.konghq.com
helm repo update

# Installer Kong avec les valeurs personnalisées
helm install kong kong/kong -f config/kong-values.yaml -n flocket
```

## Configuration des Services

Les services suivants sont configurés dans l'API Gateway:
- Authentification: `/auth/*`
- Gestion des Utilisateurs: `/users/*`
- Cercles: `/circles/*`
- Sphères: `/spheres/*`
- Messagerie: `/messaging/*`
- Notifications: `/notifications/*`
- Bien-être Numérique: `/wellbeing/*`
- Recherche: `/search/*`

## Sécurité

- Toutes les communications sont sécurisées via HTTPS
- Authentification JWT pour les routes protégées
- Limitation de taux à 100 requêtes par minute par utilisateur
- Configuration CORS pour les requêtes cross-origin
- Restriction IP pour limiter l'accès aux réseaux autorisés (10.0.0.0/8, 192.168.0.0/16)

## Transformation des Requêtes et Réponses

L'API Gateway utilise des plugins de transformation pour:
- **Requêtes**: Ajouter des en-têtes personnalisés, paramètres de requête et modifier les en-têtes existants
- **Réponses**: Standardiser les formats de réponse, ajouter des métadonnées et personnaliser les messages d'erreur

## Gestion des Erreurs

L'API Gateway fournit des réponses d'erreur standardisées pour une meilleure expérience utilisateur:

| Code | Type d'erreur | Message | En-tête spécifique |
|------|--------------|---------|-------------------|
| 401 | Authentification échouée | Veuillez vous connecter avec des identifiants valides | X-Flocket-Error: auth_failed |
| 403 | Accès refusé | Vous n'avez pas les permissions nécessaires | X-Flocket-Error: access_denied |
| 404 | Ressource non trouvée | La ressource demandée n'existe pas | X-Flocket-Error: not_found |
| 429 | Trop de requêtes | Veuillez réessayer plus tard | X-Flocket-Error: rate_limited, Retry-After: 60 |
| 500 | Erreur interne | Une erreur s'est produite lors du traitement de votre requête | X-Flocket-Error: server_error |

Les logs détaillés sont configurés avec différents niveaux de sévérité pour faciliter le diagnostic:
- Requêtes réussies: `info`
- Erreurs client: `error`
- Erreurs serveur: `critical`

## Scalabilité et Performance

L'API Gateway est conçue pour gérer un trafic élevé avec les fonctionnalités suivantes:

### Architecture Hautement Disponible
- Déploiement en mode cluster avec 3 réplicas minimum
- Autoscaling horizontal basé sur l'utilisation CPU (70%) et mémoire (80%)
- Capacité de montée en charge jusqu'à 10 réplicas selon la charge
- Anti-affinité des pods pour assurer la répartition sur différents nœuds

### Mise en Cache
- Mise en cache activée pour les requêtes GET fréquentes
- Configuration de cache spécifique par service:
  - Cache global: TTL de 300 secondes pour les requêtes GET standards
  - Service de recherche: TTL de 600 secondes pour les résultats de recherche
  - Service de cercles: TTL de 300 secondes pour les données sociales fréquemment consultées
- Stockage de cache de 128 Mo avec une durée d'inactivité de 60 minutes

### Load Balancer
- Service de type LoadBalancer pour distribuer le trafic entrant
- Répartition de charge entre les instances Kong

## Maintenance

### Renouvellement des Certificats SSL

```bash
# Exécuter le script de renouvellement des certificats
./scripts/renew-certs.sh
```

### Mise à jour de la Configuration

```bash
# Appliquer les nouvelles configurations
kubectl apply -f manifests/kong-config.yaml
```

### Surveillance

Les métriques Prometheus sont exposées sur le port 8100 et peuvent être visualisées via Grafana.

## Dépannage

Consulter les logs:
```bash
kubectl logs -f deployment/kong -n flocket
```

## Monitoring et Journalisation

Pour configurer le monitoring et la journalisation:

```bash
# Installer Prometheus, Grafana et ELK Stack
./scripts/setup-monitoring.sh
```

Pour plus d'informations, consulter la [documentation officielle de Kong](https://docs.konghq.com/). 