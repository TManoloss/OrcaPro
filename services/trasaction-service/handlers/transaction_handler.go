package handlers

import (
	"net/http"
	"strconv"
	"time"

	"transaction-service/config"
	"transaction-service/messaging"
	"transaction-service/metrics"
	"transaction-service/models"
	"transaction-service/repository"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"go.uber.org/zap"
)

type TransactionHandler struct {
	repo      *repository.TransactionRepository
	publisher *messaging.EventPublisher
	config    *config.Config
	logger    *zap.Logger
}

func NewTransactionHandler(
	repo *repository.TransactionRepository,
	publisher *messaging.EventPublisher,
	cfg *config.Config,
	logger *zap.Logger,
) *TransactionHandler {
	return &TransactionHandler{
		repo:      repo,
		publisher: publisher,
		config:    cfg,
		logger:    logger,
	}
}

type CreateTransactionRequest struct {
	Description string  `json:"description" binding:"required"`
	Amount      float64 `json:"amount" binding:"required,gt=0"`
	Category    string  `json:"category" binding:"required"`
	Type        string  `json:"type" binding:"required,oneof=income expense"`
	Date        string  `json:"date" binding:"required"` // formato: 2006-01-02T15:04:05Z
}

type UpdateTransactionRequest struct {
	Description string  `json:"description" binding:"required"`
	Amount      float64 `json:"amount" binding:"required,gt=0"`
	Category    string  `json:"category" binding:"required"`
}

// Create cria uma nova transação
func (h *TransactionHandler) Create(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	var req CreateTransactionRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Parse da data
	date, err := time.Parse(time.RFC3339, req.Date)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid date format, use RFC3339"})
		return
	}

	// Cria transação
	transaction := &models.Transaction{
		ID:          uuid.New().String(),
		UserID:      userID.(string),
		Description: req.Description,
		Amount:      req.Amount,
		Category:    req.Category,
		Type:        req.Type,
		Date:        date,
		CreatedAt:   time.Now(),
		UpdatedAt:   time.Now(),
	}

	if err := h.repo.Create(c.Request.Context(), transaction); err != nil {
		h.logger.Error("failed to create transaction", zap.Error(err))
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to create transaction"})
		return
	}

	// Publica evento
	event := messaging.TransactionEvent{
		EventType:     "transaction.created",
		TransactionID: transaction.ID,
		UserID:        transaction.UserID,
		Description:   transaction.Description,
		Amount:        transaction.Amount,
		Type:          transaction.Type,
		Category:      transaction.Category,
		Timestamp:     time.Now(),
	}

	if err := h.publisher.PublishTransactionEvent(event); err != nil {
		h.logger.Error("failed to publish transaction event", zap.Error(err))
		// Não retorna erro para o cliente, apenas loga
	}

	// Atualiza métricas
	metrics.TransactionsCreatedTotal.WithLabelValues(transaction.Type, transaction.Category).Inc()

	c.JSON(http.StatusCreated, transaction)
}

// List lista transações com filtros e paginação
func (h *TransactionHandler) List(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	// Parâmetros de query
	filters := repository.TransactionFilters{
		UserID:   userID.(string),
		Type:     c.Query("type"),
		Category: c.Query("category"),
	}

	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "10"))

	if page < 1 {
		page = 1
	}
	if pageSize < 1 || pageSize > 100 {
		pageSize = 10
	}

	transactions, total, err := h.repo.List(c.Request.Context(), filters, page, pageSize)
	if err != nil {
		h.logger.Error("failed to list transactions", zap.Error(err))
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to list transactions"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"data":      transactions,
		"total":     total,
		"page":      page,
		"page_size": pageSize,
	})
}

// GetByID busca uma transação por ID
func (h *TransactionHandler) GetByID(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	id := c.Param("id")

	transaction, err := h.repo.FindByID(c.Request.Context(), id, userID.(string))
	if err == repository.ErrTransactionNotFound {
		c.JSON(http.StatusNotFound, gin.H{"error": "transaction not found"})
		return
	}

	if err != nil {
		h.logger.Error("failed to get transaction", zap.Error(err))
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to get transaction"})
		return
	}

	c.JSON(http.StatusOK, transaction)
}

// Update atualiza uma transação
func (h *TransactionHandler) Update(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	id := c.Param("id")

	var req UpdateTransactionRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Busca transação existente
	transaction, err := h.repo.FindByID(c.Request.Context(), id, userID.(string))
	if err == repository.ErrTransactionNotFound {
		c.JSON(http.StatusNotFound, gin.H{"error": "transaction not found"})
		return
	}

	if err != nil {
		h.logger.Error("failed to get transaction", zap.Error(err))
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to get transaction"})
		return
	}

	// Atualiza campos
	transaction.Description = req.Description
	transaction.Amount = req.Amount
	transaction.Category = req.Category
	transaction.UpdatedAt = time.Now()

	if err := h.repo.Update(c.Request.Context(), transaction); err != nil {
		h.logger.Error("failed to update transaction", zap.Error(err))
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to update transaction"})
		return
	}

	// Publica evento
	event := messaging.TransactionEvent{
		EventType:     "transaction.updated",
		TransactionID: transaction.ID,
		UserID:        transaction.UserID,
		Description:   transaction.Description,
		Amount:        transaction.Amount,
		Type:          transaction.Type,
		Category:      transaction.Category,
		Timestamp:     time.Now(),
	}

	if err := h.publisher.PublishTransactionEvent(event); err != nil {
		h.logger.Error("failed to publish transaction event", zap.Error(err))
	}

	// Atualiza métricas
	metrics.TransactionsUpdatedTotal.Inc()

	c.JSON(http.StatusOK, transaction)
}

// Delete deleta uma transação
func (h *TransactionHandler) Delete(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	id := c.Param("id")

	// Busca transação antes de deletar para o evento
	transaction, err := h.repo.FindByID(c.Request.Context(), id, userID.(string))
	if err == repository.ErrTransactionNotFound {
		c.JSON(http.StatusNotFound, gin.H{"error": "transaction not found"})
		return
	}

	if err != nil {
		h.logger.Error("failed to get transaction", zap.Error(err))
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to get transaction"})
		return
	}

	if err := h.repo.Delete(c.Request.Context(), id, userID.(string)); err != nil {
		h.logger.Error("failed to delete transaction", zap.Error(err))
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to delete transaction"})
		return
	}

	// Publica evento
	event := messaging.TransactionEvent{
		EventType:     "transaction.deleted",
		TransactionID: transaction.ID,
		UserID:        transaction.UserID,
		Amount:        transaction.Amount,
		Type:          transaction.Type,
		Category:      transaction.Category,
		Timestamp:     time.Now(),
	}

	if err := h.publisher.PublishTransactionEvent(event); err != nil {
		h.logger.Error("failed to publish transaction event", zap.Error(err))
	}

	// Atualiza métricas
	metrics.TransactionsDeletedTotal.Inc()

	c.JSON(http.StatusOK, gin.H{"message": "transaction deleted successfully"})
}

// GetStats retorna estatísticas das transações
func (h *TransactionHandler) GetStats(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	stats, err := h.repo.GetStats(c.Request.Context(), userID.(string))
	if err != nil {
		h.logger.Error("failed to get stats", zap.Error(err))
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to get stats"})
		return
	}

	c.JSON(http.StatusOK, stats)
}
