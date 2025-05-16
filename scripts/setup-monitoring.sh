#!/bin/bash

# Script pour configurer le monitoring et la journalisation pour l'API Gateway ConnectSphere

# Vérifier si Helm est installé
if ! command -v helm &> /dev/null; then
    echo "Helm n'est pas installé. Veuillez l'installer avant de continuer."
    exit 1
fi

# Créer le namespace pour le monitoring
echo "Création du namespace monitoring..."
kubectl create namespace monitoring 2>/dev/null || true

# Ajouter le repo Helm pour Prometheus
echo "Ajout du repo Helm pour Prometheus..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Installer Prometheus
echo "Installation de Prometheus..."
helm install prometheus prometheus-community/prometheus \
  --namespace monitoring \
  --set server.persistentVolume.size=10Gi \
  --set alertmanager.persistentVolume.size=2Gi

# Ajouter le repo Helm pour Grafana
echo "Ajout du repo Helm pour Grafana..."
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Installer Grafana
echo "Installation de Grafana..."
helm install grafana grafana/grafana \
  --namespace monitoring \
  --set persistence.enabled=true \
  --set persistence.size=5Gi \
  --set adminPassword=connectsphere \
  --set datasources."datasources\.yaml".apiVersion=1 \
  --set datasources."datasources\.yaml".datasources[0].name=Prometheus \
  --set datasources."datasources\.yaml".datasources[0].type=prometheus \
  --set datasources."datasources\.yaml".datasources[0].url=http://prometheus-server.monitoring.svc.cluster.local \
  --set datasources."datasources\.yaml".datasources[0].access=proxy \
  --set datasources."datasources\.yaml".datasources[0].isDefault=true

# Ajouter le repo Helm pour ELK Stack
echo "Ajout du repo Helm pour ELK Stack..."
helm repo add elastic https://helm.elastic.co
helm repo update

# Installer Elasticsearch
echo "Installation d'Elasticsearch..."
helm install elasticsearch elastic/elasticsearch \
  --namespace monitoring \
  --set replicas=1 \
  --set minimumMasterNodes=1 \
  --set resources.requests.cpu=100m \
  --set resources.requests.memory=512Mi \
  --set resources.limits.cpu=1000m \
  --set resources.limits.memory=2Gi \
  --set persistence.enabled=true \
  --set persistence.size=10Gi

# Installer Kibana
echo "Installation de Kibana..."
helm install kibana elastic/kibana \
  --namespace monitoring \
  --set elasticsearchHosts=http://elasticsearch-master:9200

# Installer Filebeat
echo "Installation de Filebeat..."
helm install filebeat elastic/filebeat \
  --namespace monitoring \
  --set filebeatConfig.filebeat\.yml="filebeat.inputs:
  - type: container
    paths:
      - /var/log/containers/kong-*.log
    processors:
      - add_kubernetes_metadata:
          host: \${NODE_NAME}
          matchers:
          - logs_path:
              logs_path: \"/var/log/containers/\"
output.elasticsearch:
  host: '\${NODE_NAME}'
  hosts: 'elasticsearch-master:9200'"

# Attendre que les pods soient prêts
echo "Attente du démarrage des services de monitoring..."
kubectl wait --for=condition=ready pod -l app=prometheus-server --timeout=300s -n monitoring || true
kubectl wait --for=condition=ready pod -l app=grafana --timeout=300s -n monitoring || true
kubectl wait --for=condition=ready pod -l app=elasticsearch-master --timeout=300s -n monitoring || true
kubectl wait --for=condition=ready pod -l app=kibana --timeout=300s -n monitoring || true

# Afficher les informations d'accès
echo "Configuration du monitoring et de la journalisation terminée!"
echo ""
echo "Pour accéder à Grafana, exécutez:"
echo "kubectl port-forward svc/grafana 3000:80 -n monitoring"
echo "Puis ouvrez http://localhost:3000 dans votre navigateur"
echo "Identifiants par défaut: admin / connectsphere"
echo ""
echo "Pour accéder à Kibana, exécutez:"
echo "kubectl port-forward svc/kibana-kibana 5601:5601 -n monitoring"
echo "Puis ouvrez http://localhost:5601 dans votre navigateur" 