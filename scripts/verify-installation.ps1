# verify-installation.ps1 - Script para verificar a instalação do Traefik

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Verificando instalação do Traefik" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Verificar CRDs do Gateway API
Write-Host "1. Verificando CRDs do Gateway API..." -ForegroundColor Yellow
kubectl get crd | Select-String "gateway" -CaseSensitive:$false
Write-Host ""

# Verificar namespace
Write-Host "2. Verificando namespace traefik-system..." -ForegroundColor Yellow
kubectl get namespace traefik-system
Write-Host ""

# Verificar pods
Write-Host "3. Verificando pods do Traefik..." -ForegroundColor Yellow
kubectl get pods -n traefik-system
Write-Host ""

# Verificar service
Write-Host "4. Verificando service do Traefik..." -ForegroundColor Yellow
kubectl get svc -n traefik-system
Write-Host ""

# Verificar GatewayClass
Write-Host "5. Verificando GatewayClass..." -ForegroundColor Yellow
kubectl get gatewayclass
Write-Host ""

# Verificar Gateway
Write-Host "6. Verificando Gateway..." -ForegroundColor Yellow
kubectl get gateway -n traefik-system
Write-Host ""

# Verificar status do Gateway
Write-Host "7. Status detalhado do Gateway..." -ForegroundColor Yellow
try {
    kubectl describe gateway main-gateway -n traefik-system
} catch {
    Write-Host "Gateway 'main-gateway' não encontrado" -ForegroundColor Red
}
Write-Host ""

# Verificar logs do Traefik
Write-Host "8. Últimas linhas dos logs do Traefik..." -ForegroundColor Yellow
kubectl logs -n traefik-system -l app.kubernetes.io/name=traefik --tail=20
Write-Host ""

Write-Host "============================================" -ForegroundColor Green
Write-Host "Verificação concluída!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
