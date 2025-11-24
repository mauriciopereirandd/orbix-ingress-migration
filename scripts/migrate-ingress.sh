#!/bin/bash
# migrate-ingress.sh

if [ $# -ne 2 ]; then
    echo "Uso: $0 <ingress-name> <namespace>"
    exit 1
fi

INGRESS_NAME=$1
NAMESPACE=$2

# Exportar Ingress existente
echo "Exportando Ingress: $INGRESS_NAME"
kubectl get ingress $INGRESS_NAME -n $NAMESPACE -o yaml > "backup-$INGRESS_NAME.yaml"

# Criar HTTPRoute equivalente (template básico)
echo "Crie o HTTPRoute baseado no backup exportado"
echo "Arquivo salvo: backup-$INGRESS_NAME.yaml"

# Após criar e validar HTTPRoute:
# kubectl apply -f httproute-$INGRESS_NAME.yaml

# Validar
echo ""
echo "Após validar, você pode remover o Ingress antigo com:"
echo "kubectl delete ingress $INGRESS_NAME -n $NAMESPACE"
