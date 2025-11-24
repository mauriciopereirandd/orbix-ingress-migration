#!/bin/bash
# install-traefik.sh - Script automatizado para instalar Traefik

set -e

echo "============================================"
echo "Instalação do Traefik com Gateway API"
echo "============================================"
echo ""

# Adicionar repositório Helm
echo "1. Adicionando repositório Helm do Traefik..."
helm repo add traefik https://traefik.github.io/charts
helm repo update
echo ""

# Criar namespace
echo "2. Criando namespace traefik-system..."
kubectl create namespace traefik-system --dry-run=client -o yaml | kubectl apply -f -
echo ""

# Instalar Traefik
echo "3. Instalando Traefik via Helm..."
helm install traefik traefik/traefik \
  --namespace traefik-system \
  --values ../traefik-values.yaml \
  --version 28.0.0
echo ""

# Aguardar pods ficarem prontos
echo "4. Aguardando pods ficarem prontos..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=traefik -n traefik-system --timeout=300s
echo ""

# Aplicar Gateway
echo "5. Aplicando Gateway..."
kubectl apply -f ../gateway.yaml
echo ""

# Verificar instalação
echo "6. Verificando instalação..."
kubectl get pods -n traefik-system
kubectl get svc -n traefik-system
kubectl get gateway -n traefik-system
echo ""

echo "============================================"
echo "Instalação concluída com sucesso!"
echo "============================================"
echo ""
echo "Próximos passos:"
echo "1. Verifique o IP do LoadBalancer: kubectl get svc -n traefik-system traefik"
echo "2. Teste com a aplicação de exemplo em ../test/test-app.yaml"
