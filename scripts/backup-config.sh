#!/bin/bash

# Script pour sauvegarder les configurations Kong
# Auteur: Flocket Team
# Date: 2025

set -e

# Couleurs pour les messages
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Créer le répertoire de backup avec la date
BACKUP_DIR="backups/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo -e "${GREEN}Démarrage de la sauvegarde des configurations Kong...${NC}"

# Vérifier si le service Kong Admin est accessible
if ! curl -s http://kong-admin:8001/status > /dev/null; then
    echo -e "${RED}Erreur: Le service Kong Admin n'est pas accessible${NC}"
    exit 1
fi

# Sauvegarder les services
echo "Sauvegarde des services..."
curl -s http://kong-admin:8001/services | jq '.' > "$BACKUP_DIR/services.json"

# Sauvegarder les routes
echo "Sauvegarde des routes..."
curl -s http://kong-admin:8001/routes | jq '.' > "$BACKUP_DIR/routes.json"

# Sauvegarder les plugins
echo "Sauvegarde des plugins..."
curl -s http://kong-admin:8001/plugins | jq '.' > "$BACKUP_DIR/plugins.json"

# Sauvegarder la configuration complète
echo "Sauvegarde de la configuration complète..."
curl -s http://kong-admin:8001/config | jq '.' > "$BACKUP_DIR/kong-config.json"

# Compresser le backup
echo "Compression du backup..."
tar -czf "$BACKUP_DIR.tar.gz" "$BACKUP_DIR"
rm -rf "$BACKUP_DIR"

echo -e "${GREEN}Sauvegarde terminée avec succès!${NC}"
echo "Backup sauvegardé dans: $BACKUP_DIR.tar.gz" 