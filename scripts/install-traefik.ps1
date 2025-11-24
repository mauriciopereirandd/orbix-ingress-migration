# install-traefik.ps1 - Script automatizado para instalar Traefik

$ErrorActionPreference = "Stop"

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Instalação do Traefik com Gateway API" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Adicionar repositório Helm
Write-Host "1. Adicionando repositório Helm do Traefik..." -ForegroundColor Yellow
helm repo add traefik https://traefik.github.io/charts
helm repo update
Write-Host ""

# Criar namespace
Write-Host "2. Criando namespace traefik-system..." -ForegroundColor Yellow
kubectl create namespace traefik-system --dry-run=client -o yaml | kubectl apply -f -
Write-Host ""

# Instalar Traefik
Write-Host "3. Instalando Traefik via Helm..." -ForegroundColor Yellow
helm install traefik traefik/traefik `
  --namespace traefik-system `
  --values ..\traefik-values.yaml `
  --version 28.0.0
Write-Host ""

# Aguardar pods ficarem prontos
Write-Host "4. Aguardando pods ficarem prontos..." -ForegroundColor Yellow
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=traefik -n traefik-system --timeout=300s
Write-Host ""

# Aplicar Gateway
Write-Host "5. Aplicando Gateway..." -ForegroundColor Yellow
kubectl apply -f ..\gateway.yaml
Write-Host ""

# Verificar instalação
Write-Host "6. Verificando instalação..." -ForegroundColor Yellow
kubectl get pods -n traefik-system
kubectl get svc -n traefik-system
kubectl get gateway -n traefik-system
Write-Host ""

Write-Host "============================================" -ForegroundColor Green
Write-Host "Instalação concluída com sucesso!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "Próximos passos:"
Write-Host "1. Verifique o IP do LoadBalancer: kubectl get svc -n traefik-system traefik"
Write-Host "2. Teste com a aplicação de exemplo em ..\test\test-app.yaml"
