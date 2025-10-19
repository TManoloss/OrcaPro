# 🎯 Guia Completo da API - Equipe de Frontend

## 📋 Visão Geral

Este documento contém todas as informações necessárias para a equipe de frontend desenvolver a interface do **OrcaPro**, um sistema de gestão financeira baseado em microsserviços.

## 🏗️ Arquitetura do Backend

### Serviços Disponíveis
- **API Gateway** (Porta 8000) - Ponto único de entrada
- **Auth Service** (Porta 8001) - Autenticação e usuários
- **Transaction Service** (Porta 8002) - Transações financeiras
- **AI Service** (Porta 8003) - Categorização automática
- **Notification Service** (Porta 8004) - Notificações

### URL Base
```
Desenvolvimento: http://localhost:8000 (API Gateway)
Produção: [A SER DEFINIDO]
```

---

## 🔐 Autenticação

### Visão Geral
O sistema usa **JWT** (JSON Web Tokens) com dois tipos:
- **Access Token**: Para requisições autenticadas (expira em 1 hora)
- **Refresh Token**: Para renovar access tokens (expira em 7 dias)

### Estrutura de Token
```typescript
interface JWTPayload {
  user_id: string;
  email: string;
  name: string;
  exp: number;  // timestamp de expiração
  iat: number;  // timestamp de criação
}
```

### Headers de Autenticação
```typescript
const headers = {
  'Content-Type': 'application/json',
  'Authorization': `Bearer ${accessToken}`
}
```

---

## 📡 Endpoints da API

### 🔑 Auth Service

#### 1. Registro de Usuário
```http
POST /api/v1/auth/register
```

**Request Body:**
```typescript
interface RegisterRequest {
  email: string;      // obrigatório, formato email
  name: string;       // obrigatório
  password: string;   // obrigatório, mínimo 8 caracteres
}
```

**Response (201):**
```typescript
interface RegisterResponse {
  id: string;
  email: string;
  name: string;
}
```

**Exemplo:**
```typescript
const response = await fetch(`${API_BASE_URL}/api/v1/auth/register`, {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    email: 'user@example.com',
    name: 'João Silva',
    password: 'senhaSegura123'
  })
});

const user = await response.json();
```

#### 2. Login
```http
POST /api/v1/auth/login
```

**Request Body:**
```typescript
interface LoginRequest {
  email: string;      // obrigatório, formato email
  password: string;   // obrigatório
}
```

**Response (200):**
```typescript
interface LoginResponse {
  access_token: string;
  refresh_token: string;
  expires_in: number;  // segundos até expiração
}
```

**Exemplo:**
```typescript
const response = await fetch(`${API_BASE_URL}/api/v1/auth/login`, {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    email: 'user@example.com',
    password: 'senhaSegura123'
  })
});

const { access_token, refresh_token, expires_in } = await response.json();

// Salvar tokens no localStorage/sessionStorage
localStorage.setItem('access_token', access_token);
localStorage.setItem('refresh_token', refresh_token);
```

#### 3. Renovar Token
```http
POST /api/v1/auth/refresh
```

**Request Body:**
```typescript
interface RefreshRequest {
  refresh_token: string;  // obrigatório
}
```

**Response (200):**
```typescript
interface RefreshResponse {
  access_token: string;
  refresh_token: string;
  expires_in: number;
}
```

**Implementação de Auto-Refresh:**
```typescript
class AuthService {
  private async refreshToken(): Promise<string | null> {
    const refreshToken = localStorage.getItem('refresh_token');
    if (!refreshToken) return null;

    try {
      const response = await fetch(`${API_BASE_URL}/api/v1/auth/refresh`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ refresh_token: refreshToken })
      });

      if (response.ok) {
        const { access_token, refresh_token: newRefreshToken } = await response.json();
        localStorage.setItem('access_token', access_token);
        localStorage.setItem('refresh_token', newRefreshToken);
        return access_token;
      }
    } catch (error) {
      console.error('Erro ao renovar token:', error);
      this.logout();
    }
    return null;
  }

  async authenticatedRequest(url: string, options: RequestInit = {}) {
    let token = localStorage.getItem('access_token');
    
    let response = await fetch(url, {
      ...options,
      headers: {
        ...options.headers,
        'Authorization': `Bearer ${token}`
      }
    });

    // Se token expirou, tenta renovar
    if (response.status === 401) {
      const newToken = await this.refreshToken();
      if (newToken) {
        response = await fetch(url, {
          ...options,
          headers: {
            ...options.headers,
            'Authorization': `Bearer ${newToken}`
          }
        });
      }
    }

    return response;
  }
}
```

#### 4. Perfil do Usuário (Protegida)
```http
GET /api/v1/me
```

**Headers:**
```typescript
{
  'Authorization': 'Bearer <access_token>'
}
```

**Response (200):**
```typescript
interface UserProfile {
  id: string;
  email: string;
  name: string;
  created_at: string;  // ISO timestamp
}
```

#### 5. Logout
```http
POST /api/v1/logout
```

**Request Body:**
```typescript
interface LogoutRequest {
  refresh_token: string;  // obrigatório
}
```

**Response (200):**
```typescript
interface LogoutResponse {
  message: string;
}
```

---

### 💰 Transaction Service

#### 1. Criar Transação
```http
POST /api/v1/transactions
```

**Request Body:**
```typescript
interface CreateTransactionRequest {
  description: string;    // obrigatório
  amount: number;         // obrigatório, maior que 0
  category: string;       // obrigatório
  type: 'income' | 'expense';  // obrigatório
  date: string;           // obrigatório, formato ISO 8601 (RFC3339)
}
```

**Response (201):**
```typescript
interface Transaction {
  id: string;
  user_id: string;
  description: string;
  amount: number;
  category: string;
  type: string;
  date: string;           // ISO timestamp
  created_at: string;     // ISO timestamp
  updated_at: string;     // ISO timestamp
}
```

**Exemplo:**
```typescript
const transactionData = {
  description: 'Almoço no restaurante',
  amount: 45.50,
  category: 'Alimentação',
  type: 'expense',
  date: new Date().toISOString()
};

const response = await authService.authenticatedRequest(`${API_BASE_URL}/api/v1/transactions`, {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json'
  },
  body: JSON.stringify(transactionData)
});

const transaction = await response.json();
```

#### 2. Listar Transações
```http
GET /api/v1/transactions
```

**Query Parameters:**
```typescript
interface TransactionListParams {
  page?: number;          // padrão: 1
  page_size?: number;     // padrão: 10, máximo: 100
  type?: 'income' | 'expense';
  category?: string;
}
```

**Response (200):**
```typescript
interface TransactionListResponse {
  data: Transaction[];
  total: number;
  page: number;
  page_size: number;
}
```

**Exemplo:**
```typescript
// Buscar despesas da categoria Alimentação, página 2
const params = new URLSearchParams({
  page: '2',
  type: 'expense',
  category: 'Alimentação'
});

const response = await authService.authenticatedRequest(
  `${API_BASE_URL}/api/v1/transactions?${params}`
);
const { data, total, page, page_size } = await response.json();
```

#### 3. Buscar Transação por ID
```http
GET /api/v1/transactions/:id
```

**Response (200):**
```typescript
Transaction  // objeto único da transação
```

#### 4. Atualizar Transação
```http
PUT /api/v1/transactions/:id
```

**Request Body:**
```typescript
interface UpdateTransactionRequest {
  description: string;    // obrigatório
  amount: number;         // obrigatório, maior que 0
  category: string;       // obrigatório
}
```

**Response (200):**
```typescript
Transaction  // objeto atualizado
```

#### 5. Deletar Transação
```http
DELETE /api/v1/transactions/:id
```

**Response (200):**
```typescript
{
  message: "transaction deleted successfully"
}
```

#### 6. Estatísticas Financeiras
```http
GET /api/v1/transactions/stats
```

**Response (200):**
```typescript
interface TransactionStats {
  total_income: number;
  total_expenses: number;
  balance: number;        // receitas - despesas
  total_count: number;
  by_category: {
    [category: string]: number;  // total por categoria
  };
  last_transaction?: Transaction;
}
```

**Exemplo de uso para Dashboard:**
```typescript
const response = await authService.authenticatedRequest(
  `${API_BASE_URL}/api/v1/transactions/stats`
);
const stats = await response.json();

// Uso no dashboard
console.log(`Saldo: R$ ${stats.balance.toFixed(2)}`);
console.log(`Receitas: R$ ${stats.total_income.toFixed(2)}`);
console.log(`Despesas: R$ ${stats.total_expenses.toFixed(2)}`);
```

---

### 📊 Dashboard Endpoint (API Gateway)

#### Dados Agregados do Dashboard
```http
GET /api/v1/dashboard
```

**Response (200):**
```typescript
interface DashboardData {
  user_id: string;
  message: string;
  // Note: Este endpoint pode ser expandido com mais dados agregados
}
```

---

## 🏗️ Estrutura de Dados

### Models TypeScript

```typescript
// User Model
interface User {
  id: string;
  email: string;
  name: string;
  created_at: string;  // ISO timestamp
  updated_at: string;  // ISO timestamp
}

// Transaction Model
interface Transaction {
  id: string;
  user_id: string;
  description: string;
  amount: number;
  category: string;
  type: 'income' | 'expense';
  date: string;        // ISO timestamp
  created_at: string;  // ISO timestamp
  updated_at: string;  // ISO timestamp
}

// Transaction Statistics
interface TransactionStats {
  total_income: number;
  total_expenses: number;
  balance: number;
  total_count: number;
  by_category: Record<string, number>;
  last_transaction?: Transaction;
}

// API Response Types
interface ApiResponse<T> {
  data?: T;
  error?: string;
  message?: string;
}

interface PaginatedResponse<T> {
  data: T[];
  total: number;
  page: number;
  page_size: number;
}
```

---

## 🔧 Implementação Frontend

### 1. Cliente HTTP Configurado

```typescript
class ApiClient {
  private baseURL: string;
  private accessToken: string | null = null;

  constructor(baseURL: string = 'http://localhost:8000') {
    this.baseURL = baseURL;
    this.accessToken = localStorage.getItem('access_token');
  }

  private async makeRequest<T>(
    endpoint: string, 
    options: RequestInit = {}
  ): Promise<T> {
    const url = `${this.baseURL}${endpoint}`;
    
    const headers: HeadersInit = {
      'Content-Type': 'application/json',
      ...options.headers,
    };

    if (this.accessToken) {
      headers['Authorization'] = `Bearer ${this.accessToken}`;
    }

    const response = await fetch(url, {
      ...options,
      headers,
    });

    if (!response.ok) {
      const error = await response.json().catch(() => ({ error: 'Network error' }));
      throw new Error(error.error || `HTTP ${response.status}`);
    }

    return response.json();
  }

  // Auth methods
  async register(userData: RegisterRequest): Promise<RegisterResponse> {
    return this.makeRequest('/api/v1/auth/register', {
      method: 'POST',
      body: JSON.stringify(userData),
    });
  }

  async login(credentials: LoginRequest): Promise<LoginResponse> {
    return this.makeRequest('/api/v1/auth/login', {
      method: 'POST',
      body: JSON.stringify(credentials),
    });
  }

  async getProfile(): Promise<User> {
    return this.makeRequest('/api/v1/me');
  }

  // Transaction methods
  async getTransactions(params?: TransactionListParams): Promise<TransactionListResponse> {
    const searchParams = new URLSearchParams();
    if (params?.page) searchParams.set('page', params.page.toString());
    if (params?.page_size) searchParams.set('page_size', params.page_size.toString());
    if (params?.type) searchParams.set('type', params.type);
    if (params?.category) searchParams.set('category', params.category);

    const queryString = searchParams.toString();
    const endpoint = `/api/v1/transactions${queryString ? `?${queryString}` : ''}`;
    
    return this.makeRequest(endpoint);
  }

  async createTransaction(transaction: CreateTransactionRequest): Promise<Transaction> {
    return this.makeRequest('/api/v1/transactions', {
      method: 'POST',
      body: JSON.stringify(transaction),
    });
  }

  async updateTransaction(id: string, updates: UpdateTransactionRequest): Promise<Transaction> {
    return this.makeRequest(`/api/v1/transactions/${id}`, {
      method: 'PUT',
      body: JSON.stringify(updates),
    });
  }

  async deleteTransaction(id: string): Promise<{ message: string }> {
    return this.makeRequest(`/api/v1/transactions/${id}`, {
      method: 'DELETE',
    });
  }

  async getTransactionStats(): Promise<TransactionStats> {
    return this.makeRequest('/api/v1/transactions/stats');
  }
}
```

### 2. Gerenciamento de Estado (Exemplo com Context)

```typescript
// AuthContext.tsx
interface AuthContextType {
  user: User | null;
  isAuthenticated: boolean;
  login: (email: string, password: string) => Promise<void>;
  logout: () => void;
  register: (userData: RegisterRequest) => Promise<void>;
}

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [user, setUser] = useState<User | null>(null);
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const apiClient = new ApiClient();

  const login = async (email: string, password: string) => {
    const response = await apiClient.login({ email, password });
    
    localStorage.setItem('access_token', response.access_token);
    localStorage.setItem('refresh_token', response.refresh_token);
    
    const profile = await apiClient.getProfile();
    setUser(profile);
    setIsAuthenticated(true);
  };

  const logout = async () => {
    const refreshToken = localStorage.getItem('refresh_token');
    if (refreshToken) {
      try {
        await fetch('/api/v1/logout', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ refresh_token: refreshToken }),
        });
      } catch (error) {
        console.error('Logout error:', error);
      }
    }
    
    localStorage.removeItem('access_token');
    localStorage.removeItem('refresh_token');
    setUser(null);
    setIsAuthenticated(false);
  };

  // ... resto da implementação
};
```

### 3. Hooks Customizados

```typescript
// hooks/useTransactions.ts
export const useTransactions = (params?: TransactionListParams) => {
  const [transactions, setTransactions] = useState<Transaction[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const fetchTransactions = async () => {
    setLoading(true);
    setError(null);
    
    try {
      const response = await apiClient.getTransactions(params);
      setTransactions(response.data);
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchTransactions();
  }, [params?.page, params?.type, params?.category]);

  return {
    transactions,
    loading,
    error,
    refetch: fetchTransactions,
  };
};

// hooks/useTransactionStats.ts
export const useTransactionStats = () => {
  const [stats, setStats] = useState<TransactionStats | null>(null);
  const [loading, setLoading] = useState(false);

  const fetchStats = async () => {
    setLoading(true);
    try {
      const response = await apiClient.getTransactionStats();
      setStats(response);
    } catch (error) {
      console.error('Error fetching stats:', error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchStats();
  }, []);

  return { stats, loading, refetch: fetchStats };
};
```

---

## 🎨 Categorias Predefinidas

### Categorias Suportadas pelo Sistema
```typescript
const CATEGORIES = {
  income: [
    'Salário',
    'Freelance',
    'Investimentos',
    'Outros'
  ],
  expense: [
    'Alimentação',
    'Moradia',
    'Transporte',
    'Saúde',
    'Educação',
    'Entretenimento',
    'Compras',
    'Outros'
  ]
};
```

---

## ⚠️ Tratamento de Erros

### Códigos de Status HTTP

```typescript
// Erros comuns e como tratá-los
const handleApiError = (error: any, response?: Response) => {
  switch (response?.status) {
    case 400:
      return 'Dados inválidos fornecidos';
    case 401:
      // Token expirado ou inválido - redirecionar para login
      return 'Sessão expirada. Faça login novamente.';
    case 403:
      return 'Acesso negado';
    case 404:
      return 'Recurso não encontrado';
    case 409:
      return 'Conflito: usuário já existe';
    case 500:
      return 'Erro interno do servidor';
    default:
      return 'Erro inesperado. Tente novamente.';
  }
};
```

### Validação de Formulários

```typescript
// Exemplos de validação baseados nas regras do backend
const validateTransaction = (data: CreateTransactionRequest): string[] => {
  const errors: string[] = [];
  
  if (!data.description?.trim()) {
    errors.push('Descrição é obrigatória');
  }
  
  if (!data.amount || data.amount <= 0) {
    errors.push('Valor deve ser maior que zero');
  }
  
  if (!data.category?.trim()) {
    errors.push('Categoria é obrigatória');
  }
  
  if (!data.type || !['income', 'expense'].includes(data.type)) {
    errors.push('Tipo deve ser "income" ou "expense"');
  }
  
  if (!data.date || isNaN(Date.parse(data.date))) {
    errors.push('Data inválida');
  }
  
  return errors;
};
```

---

## 🚀 URLs de Desenvolvimento

### Serviços Principais
```typescript
const API_ENDPOINTS = {
  DEVELOPMENT: {
    API_GATEWAY: 'http://localhost:8000',
    AUTH_SERVICE: 'http://localhost:8001',
    TRANSACTION_SERVICE: 'http://localhost:8002',
    AI_SERVICE: 'http://localhost:8003',
    NOTIFICATION_SERVICE: 'http://localhost:8004',
  },
  // Adicionar URLs de produção quando disponíveis
  PRODUCTION: {
    API_GATEWAY: 'https://api.orcapro.com',
    // ... outros serviços
  }
};
```

### Ferramentas de Monitoramento (Desenvolvimento)
```typescript
const MONITORING_URLS = {
  GRAFANA: 'http://localhost:3000',          // Dashboards
  PROMETHEUS: 'http://localhost:9090',       // Métricas
  JAEGER: 'http://localhost:16686',          // Tracing
  RABBITMQ: 'http://localhost:15672',        // Message Queue
};
```

---

## 📱 Considerações Mobile/Responsivo

### Headers para Mobile
```typescript
const mobileHeaders = {
  'Content-Type': 'application/json',
  'User-Agent': 'OrcaPro-Mobile/1.0',
  'Accept': 'application/json',
};
```

### Paginação Otimizada para Mobile
```typescript
// Carregar menos itens por página em dispositivos móveis
const getPageSize = () => {
  return window.innerWidth < 768 ? 10 : 20;
};
```

---

## 🧪 Como Testar a API

### 1. Teste Manual com cURL
```bash
# 1. Registrar usuário
curl -X POST http://localhost:8000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "name": "Test User",
    "password": "senha123456"
  }'

# 2. Fazer login e salvar token
TOKEN=$(curl -s -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"senha123456"}' \
  | jq -r '.access_token')

# 3. Criar transação
curl -X POST http://localhost:8000/api/v1/transactions \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "description": "Teste de transação",
    "amount": 100.50,
    "category": "Alimentação",
    "type": "expense",
    "date": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"
  }'

# 4. Listar transações
curl http://localhost:8000/api/v1/transactions \
  -H "Authorization: Bearer $TOKEN"
```

### 2. Teste de Health Check
```bash
curl http://localhost:8000/health
```

---

## 📚 Recursos Adicionais

### Documentação Técnica
- [Guia Completo do Projeto](PROJETO_COMPLETO.md)
- [Documentação da API](FASE1_README.md)
- [Guia de Início Rápido](guides/INICIO_RAPIDO.md)

### Ferramentas Úteis
- **Postman Collection**: Coleção de requisições para testar a API
- **Insomnia**: Alternativa ao Postman para testar endpoints
- **React DevTools**: Para debug do estado da aplicação
- **Network Tab**: Para inspecionar requisições HTTP

---

## 🆘 Suporte e Contato

### Em Caso de Problemas
1. Verifique se todos os serviços estão rodando
2. Teste os endpoints com cURL primeiro
3. Verifique os logs dos serviços:
   ```bash
   docker-compose logs auth-service
   docker-compose logs transaction-service
   ```

### Informações do Ambiente
- **Versão da API**: v1
- **Formato de Data**: ISO 8601 (RFC3339)
- **Timeout**: Configurar timeout de 30s nas requisições
- **Rate Limiting**: Implementado no API Gateway

---

**📋 Checklist para a Equipe Frontend:**

- [ ] Configurar cliente HTTP com interceptors para autenticação
- [ ] Implementar gerenciamento de estado (Redux/Context)
- [ ] Criar hooks customizados para cada endpoint
- [ ] Implementar tratamento de erros global
- [ ] Configurar auto-refresh de tokens
- [ ] Implementar loading states e skeletons
- [ ] Criar validação de formulários
- [ ] Testar em diferentes dispositivos
- [ ] Implementar paginação
- [ ] Configurar variáveis de ambiente para diferentes ambientes

---

**Última atualização**: Outubro 2025  
**Versão**: 1.0  
**Mantido por**: Equipe de Backend
