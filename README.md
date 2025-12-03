# Traefik Migration - MVP

Migração do Nginx Ingress para Traefik usando **IngressRoute (CRD nativo)** e **Gateway API**.

## 🎯 Objetivo

Separar chamadas de **porta** das chamadas dos **agents** usando o novo Traefik no namespace `traefik-system`.

**IMPORTANTE**: O Nginx antigo não deve ser alterado em hipótese alguma.

## 📁 Estrutura

```
.
├── DEPLOY_STATUS.md                    # Status atual do deployment
├── README.md                           # Este arquivo
├── traefik-values.yaml                 # Helm values do Traefik
├── traefik-gatewayclass.yaml           # GatewayClass para Gateway API
├── gateway.yaml                        # Gateway principal (portas 8000/8443)
├── traefik-endpointslices-rbac.yaml    # RBAC necessário
├── orbix-tls-reference-grant.yaml      # Acesso ao TLS do namespace orbix
└── test/
    ├── test-app.yaml                   # App whoami para testes (2 replicas)
    ├── test-ingressroute.yaml          # Exemplo IngressRoute (HTTP)
    └── test-httproute.yaml             # Exemplo HTTPRoute (Gateway API)
```

## ✅ Status Atual

- **Traefik**: ✅ Deployado e operacional (2/2 pods)
- **Gateway API**: ✅ Habilitado e funcional
- **IngressRoute**: ✅ Testado com sucesso
- **HTTPRoute**: ✅ Testado com sucesso
- **LoadBalancer**: ✅ IP `68.220.28.215`

## 🚀 Deploy (Já Aplicado)

O ambiente já está configurado. Para replicar:

### 1. Atualizar Traefik

```bash
helm upgrade traefik traefik/traefik --namespace traefik-system --values traefik-values.yaml
```

### 2. Aplicar Gateway API resources

```bash
kubectl apply -f traefik-gatewayclass.yaml
kubectl apply -f traefik-endpointslices-rbac.yaml
kubectl apply -f gateway.yaml
kubectl apply -f orbix-tls-reference-grant.yaml
```

### 3. Deploy app de teste

```bash
kubectl apply -f test/test-app.yaml
kubectl apply -f test/test-ingressroute.yaml
kubectl apply -f test/test-httproute.yaml
```

## 🧪 Testes

### IngressRoute (Traefik nativo)

```bash
# Path: /whoami
curl http://68.220.28.215/whoami
```

**Resultado esperado**: HTTP 200 com informações do pod whoami

### HTTPRoute (Gateway API)

```bash
# Path: /whoami-gw
curl http://68.220.28.215/whoami-gw
```

**Resultado esperado**: HTTP 200 com informações do pod whoami

## 📊 Verificação

```bash
# Status do Traefik
kubectl get pods -n traefik-system
kubectl get svc -n traefik-system

# Gateway API
kubectl get gatewayclass
kubectl get gateway -n traefik-system
kubectl describe gateway main-gateway -n traefik-system

# Routes
kubectl get httproute -n test-migration
kubectl get ingressroute -n test-migration

# Logs (verificar sem erros)
kubectl logs -n traefik-system -l app.kubernetes.io/name=traefik --tail=50
```

## 🔧 Configuração

### Providers Habilitados

- ✅ **kubernetesCRD** - IngressRoute do Traefik (nativo)
- ✅ **kubernetesGateway** - Gateway API (padrão K8s)
- ❌ **kubernetesIngress** - Desabilitado

### Portas do Traefik

- **8000** - HTTP (web entrypoint)
- **8443** - HTTPS (websecure entrypoint)
- **9100** - Metrics (Prometheus)

### Gateway Listeners

- **http** - Porta 8000 (HTTP)
- **https** - Porta 8443 (HTTPS com TLS via orbix-tls)

## 🌐 LoadBalancer IPs

| Controller | IP | Namespace | Status |
|------------|-----|-----------|--------|
| **Nginx (antigo)** | `20.12.65.44` | orbix | ✅ Intocado |
| **Traefik (novo)** | `68.220.28.215` | traefik-system | ✅ Operacional |

## 📝 Próximos Passos

1. ✅ ~~Validar whoami funcionando via IP~~ - **CONCLUÍDO**
2. Migrar serviços agents do Nginx para Traefik
3. Configurar middlewares (rate limiting, timeouts, body size)
4. Atualizar DNS para apontar para novo IP
5. Configurar certificados TLS específicos se necessário

## 🔍 Troubleshooting

### Ver logs do Traefik

```bash
kubectl logs -n traefik-system -l app.kubernetes.io/name=traefik -f
```

### Verificar configuração do Gateway

```bash
kubectl describe gateway main-gateway -n traefik-system
```

### Verificar rotas

```bash
# IngressRoute
kubectl describe ingressroute whoami-ingressroute -n test-migration

# HTTPRoute
kubectl describe httproute whoami-httproute -n test-migration
```

### Restart Traefik (se necessário)

```bash
kubectl rollout restart deployment traefik -n traefik-system
```
