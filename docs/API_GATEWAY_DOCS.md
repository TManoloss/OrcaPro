# API Gateway - Documentação para Frontend

## Visão Geral

O **API Gateway** atua como ponto único de entrada para todos os microsserviços do sistema financeiro. Ele fornece autenticação centralizada, rate limiting, logging estruturado, métricas e tracing distribuído.

## 🌐 URL Base

**Ambiente Local (Desenvolvimento):**
```
http://localhost:8000
```

**Produção:**
```
https://sua-api-domain.com
```

## 🔐 Autenticação

Todos os endpoints protegidos requerem autenticação via **Bearer Token** no header:

```
Authorization: Bearer <seu-jwt-token>
```

### Como obter o token:

```javascript
// Faz login e recebe o token
const loginResponse = await fetch('http://localhost:8000/api/v1/auth/login', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    email: 'usuario@email.com',
    password: 'senha123'
  })
});

const { token } = await loginResponse.json();

// Usa o token nas próximas requisições
const headers = {
  'Authorization': `Bearer ${token}`,
  'Content-Type': 'application/json'
};
```

## 📋 Endpoints Disponíveis

### 🏥 Health Check

**GET** `/health`

Verifica se o API Gateway está funcionando.

```javascript
const response = await fetch('http://localhost:8000/health');
const health = await response.json();
// Retorna: { "status": "healthy", "service": "api-gateway", "time": 1234567890 }
```

---

### 📊 Métricas

**GET** `/metrics`

Endpoint para monitoramento (Prometheus). Não requer autenticação.

---

## 🔐 Endpoints de Autenticação

### Login
**POST** `/api/v1/auth/login`

```javascript
const response = await fetch('http://localhost:8000/api/v1/auth/login', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    email: 'usuario@email.com',
    password: 'senha123'
  })
});

const data = await response.json();
// Retorna: { "token": "jwt-token", "user": {...} }
```

### Registro
**POST** `/api/v1/auth/register`

```javascript
const response = await fetch('http://localhost:8000/api/v1/auth/register', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    name: 'Nome do Usuário',
    email: 'usuario@email.com',
    password: 'senha123'
  })
});

const data = await response.json();
// Retorna: { "message": "User created successfully", "user": {...} }
```

### Perfil do Usuário
**GET** `/api/v1/auth/me`

```javascript
const response = await fetch('http://localhost:8000/api/v1/auth/me', {
  headers: { 'Authorization': `Bearer ${token}` }
});

const user = await response.json();
// Retorna dados do usuário logado
```

### Refresh Token
**POST** `/api/v1/auth/refresh`

```javascript
const response = await fetch('http://localhost:8000/api/v1/auth/refresh', {
  method: 'POST',
  headers: { 'Authorization': `Bearer ${token}` }
});

const data = await response.json();
// Retorna novo token
```

---

## 💰 Endpoints de Transações

### Listar Transações
**GET** `/api/v1/transactions`

```javascript
const response = await fetch('http://localhost:8000/api/v1/transactions', {
  headers: { 'Authorization': `Bearer ${token}` }
});

const transactions = await response.json();
// Retorna lista paginada de transações
```

### Criar Transação
**POST** `/api/v1/transactions`

```javascript
const response = await fetch('http://localhost:8000/api/v1/transactions', {
  method: 'POST',
  headers: { 'Authorization': `Bearer ${token}` },
  body: JSON.stringify({
    type: 'income', // ou 'expense'
    amount: 100.50,
    category: 'food',
    description: 'Compra no supermercado',
    date: '2024-01-15'
  })
});

const transaction = await response.json();
// Retorna transação criada
```

### Buscar Transação por ID
**GET** `/api/v1/transactions/{id}`

```javascript
const response = await fetch(`http://localhost:8000/api/v1/transactions/${transactionId}`, {
  headers: { 'Authorization': `Bearer ${token}` }
});

const transaction = await response.json();
```

### Atualizar Transação
**PUT** `/api/v1/transactions/{id}`

```javascript
const response = await fetch(`http://localhost:8000/api/v1/transactions/${transactionId}`, {
  method: 'PUT',
  headers: { 'Authorization': `Bearer ${token}` },
  body: JSON.stringify({
    amount: 150.00,
    description: 'Compra atualizada'
  })
});

const transaction = await response.json();
```

### Deletar Transação
**DELETE** `/api/v1/transactions/{id}`

```javascript
const response = await fetch(`http://localhost:8000/api/v1/transactions/${transactionId}`, {
  method: 'DELETE',
  headers: { 'Authorization': `Bearer ${token}` }
});

// Retorna 204 No Content se sucesso
```

### Estatísticas de Transações
**GET** `/api/v1/transactions/stats`

```javascript
const response = await fetch('http://localhost:8000/api/v1/transactions/stats', {
  headers: { 'Authorization': `Bearer ${token}` }
});

const stats = await response.json();
// Retorna estatísticas agregadas (total, média, categorias, etc.)
```

---

## 📊 Dashboard (Endpoint Agregado)

**GET** `/api/v1/dashboard`

Este endpoint retorna dados agregados do usuário e estatísticas em uma única chamada, ideal para dashboards.

```javascript
const response = await fetch('http://localhost:8000/api/v1/dashboard', {
  headers: { 'Authorization': `Bearer ${token}` }
});

const dashboard = await response.json();
// Retorna:
// {
//   "user_id": "user123",
//   "user": { "name": "...", "email": "..." },
//   "stats": { "total_income": 5000, "total_expense": 2000, ... }
// }
```

---

## 🛠️ Tratamento de Erros

O API Gateway retorna erros padronizados:

```javascript
{
  "error": "Mensagem de erro descritiva",
  "code": "ERROR_CODE", // Opcional
  "details": {} // Dados adicionais quando necessário
}
```

### Códigos de Status Comuns:

- `200` - Success
- `201` - Created
- `400` - Bad Request (dados inválidos)
- `401` - Unauthorized (token inválido/ausente)
- `404` - Not Found
- `429` - Too Many Requests (rate limit)
- `500` - Internal Server Error

---

## 🔒 Segurança e Rate Limiting

- **CORS habilitado** para todas as origens (`*`)
- **Rate Limiting**: 100 requests por minuto por IP
- **HTTPS recomendado** em produção
- **JWT tokens** com expiração automática

---

## 📈 Monitoramento

O sistema inclui métricas detalhadas:

- **Latência** de cada endpoint
- **Taxa de erro** por serviço
- **Número de requests** por minuto
- **Tracing distribuído** via Jaeger

Métricas disponíveis em: `http://localhost:8000/metrics`

---

## 🚀 Exemplos Completos

### Login e Dashboard

```javascript
class FinanceAPI {
  constructor(baseURL = 'http://localhost:8000') {
    this.baseURL = baseURL;
  }

  async login(email, password) {
    const response = await fetch(`${this.baseURL}/api/v1/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password })
    });

    if (!response.ok) throw new Error('Login failed');

    const data = await response.json();
    this.token = data.token;
    return data;
  }

  async getDashboard() {
    const response = await fetch(`${this.baseURL}/api/v1/dashboard`, {
      headers: {
        'Authorization': `Bearer ${this.token}`,
        'Content-Type': 'application/json'
      }
    });

    if (!response.ok) throw new Error('Failed to fetch dashboard');

    return response.json();
  }

  async createTransaction(transactionData) {
    const response = await fetch(`${this.baseURL}/api/v1/transactions`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${this.token}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(transactionData)
    });

    if (!response.ok) throw new Error('Failed to create transaction');

    return response.json();
  }
}

// Uso
const api = new FinanceAPI();
await api.login('usuario@email.com', 'senha123');
const dashboard = await api.getDashboard();
console.log(dashboard);
```

---

## 🔄 Versionamento da API

- **Versão atual**: `v1`
- **Caminho base**: `/api/v1/`
- Futuras versões serão adicionadas como `/api/v2/`

---

## 📞 Suporte

Para dúvidas ou problemas:

1. **Documentação técnica**: Consulte os endpoints acima
2. **Logs**: Verifique os logs estruturados no console
3. **Métricas**: Use `/metrics` para debugging
4. **Health Check**: Use `/health` para verificar status

---

**🎉 Pronto para integrar!** O API Gateway está configurado e todos os serviços estão disponíveis através de um único ponto de entrada seguro e monitorado.
