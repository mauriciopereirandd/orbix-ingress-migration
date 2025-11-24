# migrate-ingress.ps1
param(
    [Parameter(Mandatory=$true)]
    [string]$IngressName,
    
    [Parameter(Mandatory=$true)]
    [string]$Namespace
)

# Exportar Ingress existente
Write-Host "Exportando Ingress: $IngressName"
kubectl get ingress $IngressName -n $Namespace -o yaml > "backup-$IngressName.yaml"

# Criar HTTPRoute equivalente (template básico)
Write-Host "Crie o HTTPRoute baseado no backup exportado"
Write-Host "Arquivo salvo: backup-$IngressName.yaml"

# Após criar e validar HTTPRoute:
# kubectl apply -f httproute-$IngressName.yaml

# Validar
Write-Host "`nApós validar, você pode remover o Ingress antigo com:"
Write-Host "kubectl delete ingress $IngressName -n $Namespace"
