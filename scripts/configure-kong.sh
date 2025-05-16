#!/bin/bash

# Script pour configurer les services et routes dans Kong pour Flocket

# Variables
KONG_ADMIN_URL="http://localhost:8001"
# Si vous utilisez kubectl port-forward, exécutez d'abord:
# kubectl port-forward svc/kong-admin 8001:8001 -n flocket

# Fonction pour créer un service et sa route
create_service_and_route() {
  local service_name=$1
  local service_url=$2
  local route_path=$3
  
  echo "Création du service $service_name..."
  curl -s -X POST $KONG_ADMIN_URL/services \
    -d name=$service_name \
    -d url=$service_url
  
  echo "Création de la route pour $service_name..."
  curl -s -X POST $KONG_ADMIN_URL/services/$service_name/routes \
    -d name=$service_name-route \
    -d paths[]="/$route_path/*"
}

# Création des services et routes
echo "Configuration des services et routes dans Kong..."

create_service_and_route "auth-service" "http://auth-service:3000" "auth"
create_service_and_route "users-service" "http://users-service:3000" "users"
create_service_and_route "circles-service" "http://circles-service:3000" "circles"
create_service_and_route "spheres-service" "http://spheres-service:3000" "spheres"
create_service_and_route "messaging-service" "http://messaging-service:3000" "messaging"
create_service_and_route "notifications-service" "http://notifications-service:3000" "notifications"
create_service_and_route "wellbeing-service" "http://wellbeing-service:3000" "wellbeing"
create_service_and_route "search-service" "http://search-service:3000" "search"

# Configuration du plugin JWT pour l'authentification
echo "Configuration du plugin JWT..."

# Activer JWT globalement sauf pour les routes publiques
curl -s -X POST $KONG_ADMIN_URL/plugins \
  -d name=jwt \
  -d config.secret_is_base64=false \
  -d config.run_on_preflight=true \
  -d config.anonymous=null

# Créer des exceptions pour les routes publiques (inscription et connexion)
echo "Création des exceptions pour les routes publiques..."

# Route d'inscription
curl -s -X POST $KONG_ADMIN_URL/routes/auth-service-route/plugins \
  -d name=request-termination \
  -d config.status_code=200 \
  -d config.message="Public route" \
  -d config.content_type="application/json" \
  -d config.body='{"message":"Public route"}' \
  -d disabled=true

# Limitation de taux
echo "Configuration de la limitation de taux..."
curl -s -X POST $KONG_ADMIN_URL/plugins \
  -d name=rate-limiting \
  -d config.minute=100 \
  -d config.policy=local \
  -d config.limit_by=consumer \
  -d config.header_name="X-Consumer-ID" \
  -d config.hide_client_headers=false \
  -d config.error_message="Limite de taux dépassée. Veuillez réessayer plus tard."

# Configuration CORS
echo "Configuration CORS..."
curl -s -X POST $KONG_ADMIN_URL/plugins \
  -d name=cors \
  -d config.origins="https://flocket.com" \
  -d config.methods="GET,POST,PUT,DELETE,OPTIONS,PATCH" \
  -d config.headers="Content-Type,Authorization,X-Requested-With" \
  -d config.exposed_headers="X-Auth-Token" \
  -d config.credentials=true \
  -d config.max_age=3600

# Configuration de la journalisation HTTP
echo "Configuration de la journalisation..."
curl -s -X POST $KONG_ADMIN_URL/plugins \
  -d name=http-log \
  -d config.http_endpoint="http://logging-service:8080" \
  -d config.method="POST" \
  -d config.timeout=10000 \
  -d config.keepalive=60000 \
  -d config.content_type="application/json" \
  -d config.log_level="debug" \
  -d config.successful_severity="info" \
  -d config.client_errors_severity="error" \
  -d config.server_errors_severity="critical"

# Configuration de la restriction IP
echo "Configuration de la restriction IP..."
curl -s -X POST $KONG_ADMIN_URL/plugins \
  -d name=ip-restriction \
  -d config.allow=["10.0.0.0/8", "192.168.0.0/16"] \
  -d config.message="Accès restreint aux adresses IP autorisées"

# Configuration du Request Transformer
echo "Configuration du Request Transformer..."
curl -s -X POST $KONG_ADMIN_URL/plugins \
  -d name=request-transformer \
  -d config.add.headers="X-Flocket-Version:1.0" \
  -d config.add.querystring="api_version=1.0" \
  -d config.remove.headers="X-Powered-By" \
  -d config.replace.headers="Host:api.flocket.com"

# Configuration du Response Transformer
echo "Configuration du Response Transformer..."
curl -s -X POST $KONG_ADMIN_URL/plugins \
  -d name=response-transformer \
  -d config.add.headers="X-Flocket-API:v1.0" \
  -d config.add.json="meta.version:1.0,meta.generated_at:$(date +%s)" \
  -d config.remove.headers="Server" \
  -d config.replace.json="error.message:Une erreur s'est produite,error.details:Contactez le support technique"

# Configuration de la mise en cache
echo "Configuration de la mise en cache..."

# Configuration globale du plugin proxy-cache
curl -s -X POST $KONG_ADMIN_URL/plugins \
  -d name=proxy-cache \
  -d config.response_code=200 \
  -d config.request_method="GET" \
  -d config.content_type="application/json" \
  -d config.cache_ttl=300 \
  -d config.strategy=memory

# Configuration de la mise en cache pour les services de lecture fréquente
echo "Configuration de la mise en cache pour les services spécifiques..."

# Service de recherche (cache plus long pour les requêtes de recherche)
curl -s -X POST $KONG_ADMIN_URL/services/search-service/plugins \
  -d name=proxy-cache \
  -d config.response_code=200 \
  -d config.request_method="GET" \
  -d config.content_type="application/json" \
  -d config.cache_ttl=600 \
  -d config.strategy=memory

# Service de cercles (cache pour les données sociales fréquemment consultées)
curl -s -X POST $KONG_ADMIN_URL/services/circles-service/plugins \
  -d name=proxy-cache \
  -d config.response_code=200 \
  -d config.request_method="GET" \
  -d config.content_type="application/json" \
  -d config.cache_ttl=300 \
  -d config.strategy=memory

# Configuration de la gestion des erreurs
echo "Configuration de la gestion des erreurs..."
# Plugin pour les erreurs 401 (Unauthorized)
curl -s -X POST $KONG_ADMIN_URL/plugins \
  -d name=response-transformer \
  -d config.add.json="error.code:401,error.message:Authentification échouée,error.details:Veuillez vous connecter avec des identifiants valides" \
  -d config.add.headers="X-Flocket-Error:auth_failed" \
  -d config.remove.headers="WWW-Authenticate" \
  -d config.replace.json="error.status:401" \
  -d config.if_status="401"

# Plugin pour les erreurs 403 (Forbidden)
curl -s -X POST $KONG_ADMIN_URL/plugins \
  -d name=response-transformer \
  -d config.add.json="error.code:403,error.message:Accès refusé,error.details:Vous n'avez pas les permissions nécessaires" \
  -d config.add.headers="X-Flocket-Error:access_denied" \
  -d config.replace.json="error.status:403" \
  -d config.if_status="403"

# Plugin pour les erreurs 404 (Not Found)
curl -s -X POST $KONG_ADMIN_URL/plugins \
  -d name=response-transformer \
  -d config.add.json="error.code:404,error.message:Ressource non trouvée,error.details:La ressource demandée n'existe pas" \
  -d config.add.headers="X-Flocket-Error:not_found" \
  -d config.replace.json="error.status:404" \
  -d config.if_status="404"

# Plugin pour les erreurs 429 (Too Many Requests)
curl -s -X POST $KONG_ADMIN_URL/plugins \
  -d name=response-transformer \
  -d config.add.json="error.code:429,error.message:Trop de requêtes,error.details:Veuillez réessayer plus tard" \
  -d config.add.headers="X-Flocket-Error:rate_limited,Retry-After:60" \
  -d config.replace.json="error.status:429" \
  -d config.if_status="429"

# Plugin pour les erreurs 500 (Internal Server Error)
curl -s -X POST $KONG_ADMIN_URL/plugins \
  -d name=response-transformer \
  -d config.add.json="error.code:500,error.message:Erreur interne du serveur,error.details:Une erreur s'est produite lors du traitement de votre requête" \
  -d config.add.headers="X-Flocket-Error:server_error" \
  -d config.replace.json="error.status:500" \
  -d config.if_status="500"

# Configuration de Prometheus pour le monitoring
echo "Configuration de Prometheus..."
curl -s -X POST $KONG_ADMIN_URL/plugins \
  -d name=prometheus

echo "Configuration de Kong terminée avec succès!" 