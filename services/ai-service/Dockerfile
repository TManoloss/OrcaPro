# Build stage
FROM python:3.11-slim

# Instala dependências do sistema
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copia requirements e instala dependências
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copia código fonte
COPY . .

# Cria diretório para modelos
RUN mkdir -p /app/models

# Expõe porta de métricas
EXPOSE 8003

# Comando para executar
CMD ["python", "-u", "main.py"]
