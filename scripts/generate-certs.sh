#!/bin/bash

# Script pour générer les certificats SSL pour Kong
# Auteur: Flocket Team
# Date: 2025

set -e

# Couleurs pour les messages
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}Génération des certificats SSL pour Kong...${NC}"

# Vérifier si OpenSSL est installé
if ! command -v openssl &> /dev/null; then
    echo -e "${RED}Erreur: OpenSSL n'est pas installé${NC}"
    exit 1
fi

# Créer le répertoire des certificats s'il n'existe pas
mkdir -p certs

# Générer la clé privée CA
echo "Génération de la clé privée CA..."
openssl genrsa -out certs/ca.key 4096

# Générer le certificat CA
echo "Génération du certificat CA..."
openssl req -new -x509 -key certs/ca.key -out certs/ca.crt -days 3650 \
    -subj "/C=FR/ST=IDF/L=Paris/O=Flocket/CN=Flocket CA"

# Générer la clé privée pour Kong
echo "Génération de la clé privée Kong..."
openssl genrsa -out certs/kong.key 2048

# Créer la demande de signature de certificat (CSR)
echo "Création de la demande de signature de certificat..."
openssl req -new -key certs/kong.key -out certs/kong.csr \
    -subj "/C=FR/ST=IDF/L=Paris/O=Flocket/CN=api.flocket.com"

# Signer le certificat avec le CA
echo "Signature du certificat Kong avec le CA..."
openssl x509 -req -in certs/kong.csr \
    -CA certs/ca.crt \
    -CAkey certs/ca.key \
    -CAcreateserial \
    -out certs/kong.crt \
    -days 365 \
    -sha256

# Vérifier si les certificats ont été générés correctement
echo "Vérification des certificats..."
if ! openssl x509 -in certs/ca.crt -text -noout &> /dev/null; then
    echo -e "${RED}Erreur: La génération du certificat CA a échoué${NC}"
    exit 1
fi

if ! openssl x509 -in certs/kong.crt -text -noout &> /dev/null; then
    echo -e "${RED}Erreur: La génération du certificat Kong a échoué${NC}"
    exit 1
fi

# Nettoyer les fichiers temporaires
rm -f certs/kong.csr certs/ca.srl

echo -e "${GREEN}Certificats générés avec succès!${NC}"
echo "Certificat CA: certs/ca.crt"
echo "Clé privée CA: certs/ca.key"
echo "Certificat Kong: certs/kong.crt"
echo "Clé privée Kong: certs/kong.key" 