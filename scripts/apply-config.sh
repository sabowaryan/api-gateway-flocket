#!/bin/bash

# Script pour appliquer les configurations à Kong via son API Admin
# Auteur: Flocket Team
# Date: 2025

set -e

# Couleurs pour les messages
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}Démarrage de l'application des configurations Kong...${NC}"

# Vérifier si le service Kong Admin est accessible
if ! curl -s http://kong-admin:8001/status > /dev/null; then
    echo -e "${RED}Erreur: Le service Kong Admin n'est pas accessible${NC}"
    exit 1
fi

# Appliquer les configurations via l'API Admin
echo "Application des services..."
curl -X POST http://kong-admin:8001/config \
    -F "config=@config/services.yaml" \
    -H "Content-Type: multipart/form-data"

echo "Application des routes..."
curl -X POST http://kong-admin:8001/config \
    -F "config=@config/routes.yaml" \
    -H "Content-Type: multipart/form-data"

# Appliquer les configurations des plugins
echo "Application des plugins..."
for plugin in config/plugins/*.yaml; do
    echo "Application de $(basename $plugin)..."
    curl -X POST http://kong-admin:8001/config \
        -F "config=@$plugin" \
        -H "Content-Type: multipart/form-data"
done

echo -e "${GREEN}Configuration appliquée avec succès!${NC}" 