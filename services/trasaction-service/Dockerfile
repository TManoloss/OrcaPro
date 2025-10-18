# Build stage
FROM golang:1.23-alpine AS builder

# Instala dependências necessárias
RUN apk add --no-cache git make

WORKDIR /app

# Copia go.mod e go.sum
COPY go.mod go.sum ./

# Download das dependências
RUN go mod download

# Copia o código fonte
COPY . .

# Build da aplicação
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o transaction-service ./main.go

# Runtime stage
FROM alpine:latest

# Instala ca-certificates para HTTPS e wget para healthcheck
RUN apk --no-cache add ca-certificates wget

WORKDIR /root/

# Copia o binário do build stage
COPY --from=builder /app/transaction-service .

# Expõe a porta
EXPOSE 8002

# Comando para executar
CMD ["./transaction-service"]
