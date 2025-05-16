#!/bin/bash

# Script de déploiement pour l'API Gateway Flocket

# Vérifier si kubectl est installé
if ! command -v kubectl &> /dev/null; then
    echo "kubectl n'est pas installé. Veuillez l'installer avant de continuer."
    exit 1
fi

# Vérifier si le contexte Kubernetes est configuré
if ! kubectl config current-context &> /dev/null; then
    echo "Aucun contexte Kubernetes n'est configuré. Veuillez configurer kubectl avant de continuer."
    exit 1
fi

# Créer le namespace s'il n'existe pas
echo "Création du namespace flocket..."
kubectl create namespace flocket 2>/dev/null || true

# Générer les certificats SSL si nécessaire
if [ ! -f "../certs/tls.crt" ] || [ ! -f "../certs/tls.key" ]; then
    echo "Génération des certificats SSL..."
    ./generate-certs.sh
fi

# Déployer PostgreSQL
echo "Déploiement de PostgreSQL..."
kubectl apply -f ../manifests/postgres.yaml

# Attendre que PostgreSQL soit prêt
echo "Attente du démarrage de PostgreSQL..."
kubectl wait --for=condition=ready pod -l app=postgres --timeout=300s -n flocket

# Déployer la configuration de Kong
echo "Déploiement de la configuration de Kong..."
kubectl apply -f ../manifests/kong-config.yaml

# Déployer Kong
echo "Déploiement de Kong..."
kubectl apply -f ../manifests/kong-deployment.yaml
kubectl apply -f ../manifests/kong-service.yaml
kubectl apply -f ../manifests/kong-ingress.yaml

# Attendre que Kong soit prêt
echo "Attente du démarrage de Kong..."
kubectl wait --for=condition=ready pod -l app=kong --timeout=300s -n flocket

# Configuration des services et routes dans Kong
echo "Configuration des services et routes dans Kong..."
echo "Pour configurer Kong, exécutez la commande suivante dans un terminal séparé:"
echo "kubectl port-forward svc/kong-admin 8001:8001 -n flocket"
echo "Puis exécutez: ./configure-kong.sh"

echo "Déploiement de l'API Gateway Flocket terminé avec succès!"
echo "L'API Gateway est accessible à l'adresse: https://api.flocket.com"
echo "Vous devrez configurer votre fichier hosts ou DNS pour pointer api.flocket.com vers l'adresse IP du LoadBalancer."
echo "Pour obtenir l'adresse IP du LoadBalancer, exécutez: kubectl get svc kong-proxy -n flocket" 