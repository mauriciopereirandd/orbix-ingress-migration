#!/bin/bash
# Validação Simplificada de Roteamento

echo "========================================="
echo "VALIDACAO DE ROTEAMENTO - GATEWAY API"
echo "========================================="
echo ""

# 1. Gateway Status
echo "1. GATEWAY STATUS"
echo "-----------------------------------------"
kubectl get gateway main-gateway -n traefik-system
echo ""
kubectl get gateway main-gateway -n traefik-system -o jsonpath='Status: {.status.conditions[0].reason} - {.status.conditions[0].message}{"\n"}'
echo ""

# 2. HTTPRoutes
echo "2. HTTPROUTES"
echo "-----------------------------------------"
kubectl get httproutes -n orbix
echo ""

# 3. Detalhes de cada rota
echo "3. DETALHES DAS ROTAS"
echo "-----------------------------------------"
for route in agent-api-httproute agent-logs-httproute agent-sdk-httproute agent-signalr-httproute; do
    echo ""
    echo "=== $route ==="
    kubectl get httproute $route -n orbix -o jsonpath='Hostname: {.spec.hostnames[0]}{"\n"}Path: {.spec.rules[0].matches[0].path.value}{"\n"}Service: {.spec.rules[0].backendRefs[0].name}{"\n"}'

    # Status
    accepted=$(kubectl get httproute $route -n orbix -o jsonpath='{.status.parents[0].conditions[?(@.type=="Accepted")].status}')
    resolved=$(kubectl get httproute $route -n orbix -o jsonpath='{.status.parents[0].conditions[?(@.type=="ResolvedRefs")].status}')

    echo "Status Accepted: $accepted"
    echo "Status ResolvedRefs: $resolved"

    # Verificar service existe
    service=$(kubectl get httproute $route -n orbix -o jsonpath='{.spec.rules[0].backendRefs[0].name}')
    kubectl get service $service -n orbix &>/dev/null && echo "Service OK" || echo "Service NAO ENCONTRADO"
done

# 4. Middlewares
echo ""
echo "4. MIDDLEWARES"
echo "-----------------------------------------"
kubectl get middleware -n orbix

# 5. TLS e ReferenceGrant
echo ""
echo "5. TLS CERTIFICATE"
echo "-----------------------------------------"
kubectl get secret orbix-tls -n orbix

echo ""
echo "6. REFERENCEGRANT"
echo "-----------------------------------------"
kubectl get referencegrant -n orbix 2>/dev/null || echo "ReferenceGrant nao encontrado"

# 7. Services e Endpoints
echo ""
echo "7. SERVICES E ENDPOINTS"
echo "-----------------------------------------"
for svc in agent-api-service agent-logs-service agent-sdk-service agent-signalr-service; do
    echo ""
    echo "Service: $svc"
    kubectl get service $svc -n orbix 2>/dev/null || echo "  NAO ENCONTRADO"
    kubectl get endpoints $svc -n orbix -o jsonpath='  Endpoints: {.subsets[0].addresses[*].ip}{"\n"}' 2>/dev/null || echo "  Sem endpoints"
done

# 8. Traefik Pods
echo ""
echo "8. TRAEFIK PODS"
echo "-----------------------------------------"
kubectl get pods -n traefik-system -l app.kubernetes.io/name=traefik

# 9. Comandos de teste
echo ""
echo "9. COMANDOS DE TESTE"
echo "-----------------------------------------"
echo "Teste HTTP direto:"
echo "  curl -H 'Host: homolog-agent.nddorbix.com' http://68.220.28.215:8000/agent-api/"
echo ""
echo "Teste HTTPS:"
echo "  curl -k https://homolog-agent.nddorbix.com:8443/agent-api/"
echo ""
echo "Ver logs do Traefik:"
echo "  kubectl logs -n traefik-system -l app.kubernetes.io/name=traefik --tail=50 -f"

echo ""
echo "========================================="
echo "VALIDACAO CONCLUIDA"
echo "========================================="
