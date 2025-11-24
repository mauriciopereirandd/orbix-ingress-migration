# Plano de Migração: Nginx Ingress → Traefik Gateway API

## 📋 Visão Geral

Este documento descreve o processo de migração do Nginx Ingress Controller para Traefik com suporte ao Gateway API do Kubernetes, permitindo uma transição gradual e sem downtime.

## 🎯 Objetivos

- Implementar Traefik como novo Ingress Controller
- Suportar Gateway API (nova especificação do Kubernetes)
- Manter Nginx funcionando durante a transição
- Realizar migração gradual (canary migration)
- Zero downtime

## 🏗️ Arquitetura Paralela

```
┌─────────────────────────────────────────┐
│         Load Balancer / DNS             │
└────────────┬────────────────────────────┘
             │
     ┌───────┴────────┐
     │                │
┌────▼─────┐    ┌────▼──────┐
│  Nginx   │    │  Traefik  │
│ Ingress  │    │  Gateway  │
│(Atual)   │    │  (Novo)   │
└────┬─────┘    └────┬──────┘
     │                │
     └────────┬───────┘
              │
        ┌─────▼──────┐
        │  Services  │
        └────────────┘
```

## 📦 Pré-requisitos

- Kubernetes 1.26+
- Helm 3.x
- kubectl configurado
- Permissões de administrador no cluster
- Gateway API CRDs (v1.0.0+)

## 🚀 Etapa 1: Verificar Gateway API CRDs

```bash
# Verificar se os CRDs do Gateway API já estão instalados
kubectl get crd | grep -i gateway

# Ou verificar CRDs específicos
kubectl get crd gatewayclasses.gateway.networking.k8s.io
kubectl get crd gateways.gateway.networking.k8s.io
kubectl get crd httproutes.gateway.networking.k8s.io
kubectl get crd referencegrants.gateway.networking.k8s.io
```

Se não estiverem instalados:

```bash
# Instalar Gateway API CRDs (versão stable)
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.0.0/standard-install.yaml
```

## 🔧 Etapa 2: Instalação do Traefik (Modo Paralelo)

**Método Automatizado (Recomendado):**

```bash
# Linux/Mac
./scripts/install-traefik.sh

# Windows PowerShell
.\scripts\install-traefik.ps1
```

**Método Manual:**

### 2.1 Adicionar repositório Helm

```bash
helm repo add traefik https://traefik.github.io/charts
helm repo update
```

### 2.2 Criar namespace

```bash
kubectl create namespace traefik-system
```

### 2.3 Configurar valores

Edite o arquivo `traefik-values.yaml` conforme necessário (arquivo já disponível no repositório).

### 2.4 Instalar via Helm

```bash
helm install traefik traefik/traefik \
  --namespace traefik-system \
  --values traefik-values.yaml \
  --version 28.0.0
```

### 2.5 Verificar instalação

```bash
kubectl get pods -n traefik-system
kubectl get svc -n traefik-system
kubectl get gatewayclass
```

## 🔐 Etapa 3: Configurar Certificado TLS

### 3.1 Criar ReferenceGrant

Para permitir que o Traefik acesse certificados existentes em outros namespaces:

```bash
kubectl apply -f orbix-tls-reference-grant.yaml
```

Arquivo disponível em: `orbix-tls-reference-grant.yaml`

### 3.2 Verificar certificado

```bash
# Verificar se o certificado existe
kubectl get secret orbix-tls -n orbix

# Ver detalhes
kubectl describe secret orbix-tls -n orbix
```

## 🌐 Etapa 4: Criar Gateway Principal

### 4.1 Aplicar Gateway

```bash
kubectl apply -f gateway.yaml
```

Arquivo disponível em: `gateway.yaml` (já configurado com certificado `orbix-tls`)

### 4.2 Verificar status

```bash
kubectl get gateway -n traefik-system
kubectl describe gateway main-gateway -n traefik-system
```

## 🧪 Etapa 5: Teste com Aplicação de Exemplo

### 5.1 Aplicar aplicação de teste

```bash
kubectl apply -f test/test-app.yaml
kubectl apply -f test/test-httproute.yaml
```

### 5.2 Verificar deployment

```bash
kubectl get pods -n test-migration
kubectl get httproute -n test-migration
```

### 5.3 Testar acesso

```bash
# Obter IP do Traefik
TRAEFIK_IP=$(kubectl get svc -n traefik-system traefik -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Testar
curl -H "Host: whoami.test.example.com" http://$TRAEFIK_IP
```

## 📊 Etapa 6: Verificação Completa

Execute o script de verificação:

```bash
# Linux/Mac
./scripts/verify-installation.sh

# Windows PowerShell
.\scripts\verify-installation.ps1
```

## 🔄 Etapa 7: Migrar Aplicações Existentes

### 7.1 Usar script de migração

```bash
# Linux/Mac
./scripts/migrate-ingress.sh <ingress-name> <namespace>

# Windows PowerShell
.\scripts\migrate-ingress.ps1 -IngressName <name> -Namespace <ns>
```

### 7.2 Exemplo de conversão

Consulte exemplos em: `examples/ingress-to-httproute-example.yaml`

## 📈 Etapa 8: Monitoramento

### 8.1 Verificar status do Traefik

```bash
# Status dos pods
kubectl get pods -n traefik-system

# Logs em tempo real
kubectl logs -n traefik-system -l app.kubernetes.io/name=traefik -f

# Métricas
kubectl port-forward -n traefik-system svc/traefik 9100:9100
# Acessar: http://localhost:9100/metrics
```

### 8.2 Dashboard do Traefik

```bash
# Port-forward para dashboard
kubectl port-forward -n traefik-system $(kubectl get pods -n traefik-system -l app.kubernetes.io/name=traefik -o name | head -n1) 9000:9000

# Acessar: http://localhost:9000/dashboard/
```

## 🚨 Etapa 9: Rollback

### 9.1 Procedimento de rollback

```bash
# Se necessário reverter para Nginx:

# 1. Reverter DNS/Load Balancer para Nginx
# 2. Remover HTTPRoutes
kubectl delete httproute <route-name> -n <namespace>

# 3. Opcional: Desinstalar Traefik (manter para retry)
helm uninstall traefik -n traefik-system

# 4. Validar que Nginx está servindo tráfego
kubectl get pods -n ingress-nginx
```

## 📚 Recursos e Referências

### Arquivos do Projeto

- `traefik-values.yaml` - Configuração do Helm Chart
- `gateway.yaml` - Definição do Gateway principal
- `orbix-tls-reference-grant.yaml` - Permissão para acessar certificado TLS
- `scripts/install-traefik.sh|.ps1` - Scripts de instalação automatizada
- `scripts/verify-installation.sh|.ps1` - Scripts de verificação
- `scripts/migrate-ingress.sh|.ps1` - Scripts auxiliares de migração
- `test/test-app.yaml` - Aplicação de teste whoami
- `test/test-httproute.yaml` - HTTPRoute de teste
- `examples/ingress-to-httproute-example.yaml` - Exemplos de conversão
- `examples/tls-reference-grant.yaml` - Exemplo de ReferenceGrant

### Documentação oficial
- [Traefik Gateway API](https://doc.traefik.io/traefik/providers/kubernetes-gateway/)
- [Kubernetes Gateway API](https://gateway-api.sigs.k8s.io/)
- [Traefik Helm Chart](https://github.com/traefik/traefik-helm-chart)

### Comandos úteis

```bash
# Listar todos os Ingress atuais
kubectl get ingress --all-namespaces

# Listar todos os HTTPRoutes
kubectl get httproute --all-namespaces

# Ver eventos do cluster
kubectl get events --sort-by='.lastTimestamp' -A

# Comparar IPs dos load balancers
kubectl get svc -A | grep LoadBalancer
```

## 🎯 Timeline Sugerido

| Fase | Duração | Atividades |
|------|---------|------------|
| Preparação | 1-2 dias | Verificar CRDs, instalar Traefik, configurar TLS |
| Testes | 1 dia | Validar com aplicação de teste |
| Piloto | 3-5 dias | Migrar 1-2 aplicações não-críticas |
| Migração gradual | 2-4 semanas | Migrar aplicações restantes |
| Estabilização | 1 semana | Monitoramento intensivo |
| Descomissionamento | 1 semana | Remover Nginx |

## ⚠️ Observações Importantes

1. **IPs diferentes**: Traefik receberá um IP diferente do Nginx inicialmente
2. **Coexistência**: Ambos controllers podem rodar simultaneamente
3. **DNS**: Atualize DNS gradualmente para migrar tráfego
4. **TLS**: Certificado `orbix-tls` (*.nddorbix.com) já configurado via ReferenceGrant
5. **Annotations**: Traefik usa annotations diferentes do Nginx
6. **Testing**: Sempre teste em ambiente de desenvolvimento primeiro

## ✅ Conclusão

Este documento fornece um roteiro completo para migração gradual do Nginx Ingress para Traefik com Gateway API, minimizando riscos e permitindo rollback a qualquer momento.

**Sequência de Execução:**

1. ✅ Verificar Gateway API CRDs (Etapa 1)
2. 🔧 Instalar Traefik (Etapa 2)
3. 🔐 Configurar certificado TLS (Etapa 3)
4. 🌐 Criar Gateway (Etapa 4)
5. 🧪 Testar com app exemplo (Etapa 5)
6. 📊 Verificar instalação (Etapa 6)
7. 🔄 Migrar aplicações (Etapa 7)
8. 📈 Monitorar (Etapa 8)

**Certificado TLS configurado:**
- Secret: `orbix-tls` (namespace: `orbix`)
- Domínio: `*.nddorbix.com`
- Válido até: 22/11/2026