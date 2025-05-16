#!/bin/bash

# Script pour générer des certificats SSL auto-signés pour Flocket API Gateway

# Créer le répertoire des certificats s'il n'existe pas
mkdir -p ../certs

# Générer une clé privée
openssl genrsa -out ../certs/tls.key 2048

# Générer un certificat auto-signé valide pour 365 jours
openssl req -x509 -new -nodes -key ../certs/tls.key -sha256 -days 365 -out ../certs/tls.crt \
  -subj "/C=FR/ST=Paris/L=Paris/O=Flocket/OU=IT/CN=api.flocket.com"

echo "Certificats générés avec succès dans le dossier certs/"
echo "Création du secret Kubernetes..."

# Créer le secret Kubernetes (nécessite kubectl configuré)
kubectl create namespace flocket 2>/dev/null || true
kubectl create secret tls kong-ssl \
  --cert=../certs/tls.crt \
  --key=../certs/tls.key \
  --namespace=flocket

echo "Secret 'kong-ssl' créé dans le namespace 'flocket'" 