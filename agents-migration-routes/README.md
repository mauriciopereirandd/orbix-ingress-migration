# Migração dos Agents para Traefik Gateway API

## 📋 Visão Geral

Migração das rotas dos agents do Nginx Ingress para Traefik usando **Gateway API** com **Middlewares** do Traefik para manter as mesmas configurações de rate limiting, body size e timeouts.

## 📁 Arquivos

### HTTPRoutes (um por agent)
- `agent-api-httproute.yaml` - HTTPRoute para Agent API
- `agent-logs-httproute.yaml` - HTTPRoute para Agent Logs
- `agent-sdk-httproute.yaml` - HTTPRoute para Agent SDK
- `agent-signalr-httproute.yaml` - HTTPRoute para Agent SignalR
- `agents-httproutes.yaml` - HTTPRoute consolidado (alternativa)

### Middlewares
- `agents-middlewares.yaml` - Middlewares do Traefik para rate limiting e buffering

## 🔄 Mapeamento de Configurações

### Agent API
| Config | Nginx | Traefik Middleware |
|--------|-------|-------------------|
| Rate Limit | 50 rps / 500 rpm | 50 rps average, burst 100 |
| Body Size | 500m | 524288000 bytes (500MB) |
| Timeout | 240s | (configurado no traefik-values.yaml) |
| Path | `/agent-api/(.*)` → `/$1` | URLRewrite: `/agent-api/` → `/` |

### Agent Logs
| Config | Nginx | Traefik Middleware |
|--------|-------|-------------------|
| Rate Limit | 20 rps / 100 rpm | 20 rps average, burst 40 |
| Body Size | 12m | 12582912 bytes (12MB) |
| Path | `/agent-logs/(.*)` → `/$1` | URLRewrite: `/agent-logs/` → `/` |

### Agent SDK
| Config | Nginx | Traefik Middleware |
|--------|-------|-------------------|
| Rate Limit | 15 rps / 350 rpm | 15 rps average, burst 30 |
| Timeout | 240s | (configurado no traefik-values.yaml) |
| Path | `/agent-sdk/(.*)` → `/$1` | URLRewrite: `/agent-sdk/` → `/` |

### Agent SignalR
| Config | Nginx | Traefik Middleware |
|--------|-------|-------------------|
| Rate Limit | 10 rps / 200 rpm | 10 rps average, burst 20 |
| Path | `/agent-signalr/(.*)` → `/$1` | URLRewrite: `/agent-signalr/` → `/` |

## 🚀 Deploy

### 1. Aplicar Middlewares

```bash
kubectl apply -f agents-middlewares.yaml
```

### 2. Aplicar HTTPRoutes

**Opção A - Aplicar todos de uma vez:**
```bash
kubectl apply -f agent-api-httproute.yaml
kubectl apply -f agent-logs-httproute.yaml
kubectl apply -f agent-sdk-httproute.yaml
kubectl apply -f agent-signalr-httproute.yaml
```

**Opção B - Aplicar um por vez (recomendado para testes):**
```bash
# Começar só com Agent API
kubectl apply -f agent-api-httproute.yaml

# Depois de validar, aplicar os outros
kubectl apply -f agent-logs-httproute.yaml
kubectl apply -f agent-sdk-httproute.yaml
kubectl apply -f agent-signalr-httproute.yaml
```

**Opção C - Usar o consolidado (alternativa):**
```bash
kubectl apply -f agents-httproutes.yaml
```

### 3. Verificar

```bash
# Verificar middlewares
kubectl get middleware -n orbix

# Verificar HTTPRoute
kubectl get httproute -n orbix
kubectl describe httproute agents-httproute -n orbix

# Verificar Gateway
kubectl describe gateway main-gateway -n traefik-system
```

## 🧪 Testes

### Usando o IP do Traefik

```bash
# IP do Traefik
TRAEFIK_IP=68.220.28.215

# Testar Agent API
curl -H "Host: homolog-portal.nddorbix.com" http://$TRAEFIK_IP/agent-api/health

# Testar Agent Logs
curl -H "Host: homolog-portal.nddorbix.com" http://$TRAEFIK_IP/agent-logs/health

# Testar Agent SDK
curl -H "Host: homolog-portal.nddorbix.com" http://$TRAEFIK_IP/agent-sdk/health

# Testar Agent SignalR
curl -H "Host: homolog-portal.nddorbix.com" http://$TRAEFIK_IP/agent-signalr/health
```

### Testar Rate Limiting

```bash
# Deve retornar 429 (Too Many Requests) após exceder o limite
for i in {1..60}; do
  curl -H "Host: homolog-portal.nddorbix.com" \
       -o /dev/null -s -w "%{http_code}\n" \
       http://$TRAEFIK_IP/agent-api/health
done
```

## ⚠️ Importante

### TLS/HTTPS

O HTTPRoute usa o Gateway `main-gateway` que já está configurado com:
- Listener HTTPS na porta 8443
- Certificado TLS via `orbix-tls` (ReferenceGrant já aplicado)

Para HTTPS:
```bash
curl -k -H "Host: homolog-portal.nddorbix.com" https://68.220.28.215/agent-api/health
```

### Host Header Obrigatório

Como o HTTPRoute filtra por hostname (`homolog-portal.nddorbix.com`), você **DEVE** incluir o header `Host` ao testar via IP.

### DNS

Para uso em produção, atualize o DNS:
```
homolog-portal.nddorbix.com A 68.220.28.215
```

## 📝 Próximos Passos

1. ✅ Aplicar middlewares e HTTPRoutes
2. ✅ Testar todas as rotas via IP com Host header
3. Atualizar DNS para apontar para o novo IP
4. Testar em produção com clientes reais
5. Monitorar logs e métricas
6. Desabilitar rotas antigas do Nginx (após validação completa)

## 🔍 Troubleshooting

### Ver logs do Traefik

```bash
kubectl logs -n traefik-system -l app.kubernetes.io/name=traefik -f | grep agent
```

### Verificar se Middlewares foram aplicados

```bash
kubectl describe middleware agent-api-middleware -n orbix
```

### Verificar rotas no Gateway

```bash
kubectl get httproute agents-httproute -n orbix -o yaml
```

### Debug de requisição

```bash
curl -v -H "Host: homolog-portal.nddorbix.com" http://68.220.28.215/agent-api/health
```
