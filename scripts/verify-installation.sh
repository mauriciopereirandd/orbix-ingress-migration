#!/bin/bash
# verify-installation.sh - Script para verificar a instalação do Traefik

echo "============================================"
echo "Verificando instalação do Traefik"
echo "============================================"
echo ""

# Verificar CRDs do Gateway API
echo "1. Verificando CRDs do Gateway API..."
kubectl get crd | grep -i gateway
echo ""

# Verificar namespace
echo "2. Verificando namespace traefik-system..."
kubectl get namespace traefik-system
echo ""

# Verificar pods
echo "3. Verificando pods do Traefik..."
kubectl get pods -n traefik-system
echo ""

# Verificar service
echo "4. Verificando service do Traefik..."
kubectl get svc -n traefik-system
echo ""

# Verificar GatewayClass
echo "5. Verificando GatewayClass..."
kubectl get gatewayclass
echo ""

# Verificar Gateway
echo "6. Verificando Gateway..."
kubectl get gateway -n traefik-system
echo ""

# Verificar status do Gateway
echo "7. Status detalhado do Gateway..."
kubectl describe gateway main-gateway -n traefik-system 2>/dev/null || echo "Gateway 'main-gateway' não encontrado"
echo ""

# Verificar logs do Traefik
echo "8. Últimas linhas dos logs do Traefik..."
kubectl logs -n traefik-system -l app.kubernetes.io/name=traefik --tail=20
echo ""

echo "============================================"
echo "Verificação concluída!"
echo "============================================"
