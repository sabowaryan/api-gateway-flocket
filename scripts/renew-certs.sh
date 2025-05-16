#!/bin/bash

# Script pour renouveler les certificats SSL pour Flocket API Gateway

# Sauvegarde des certificats existants
echo "Sauvegarde des certificats existants..."
mkdir -p ../certs/backup
cp ../certs/tls.crt ../certs/backup/tls.crt.$(date +%Y%m%d)
cp ../certs/tls.key ../certs/backup/tls.key.$(date +%Y%m%d)

# Génération des nouveaux certificats
echo "Génération des nouveaux certificats..."
openssl genrsa -out ../certs/tls.key 2048
openssl req -x509 -new -nodes -key ../certs/tls.key -sha256 -days 365 -out ../certs/tls.crt \
  -subj "/C=FR/ST=Paris/L=Paris/O=Flocket/OU=IT/CN=api.flocket.com"

# Mise à jour du secret Kubernetes
echo "Mise à jour du secret Kubernetes..."
kubectl delete secret kong-ssl --namespace=flocket
kubectl create secret tls kong-ssl \
  --cert=../certs/tls.crt \
  --key=../certs/tls.key \
  --namespace=flocket

# Redémarrage des pods Kong pour appliquer les nouveaux certificats
echo "Redémarrage des pods Kong..."
kubectl rollout restart deployment kong --namespace=flocket

echo "Renouvellement des certificats terminé avec succès!" 