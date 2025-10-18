package repository

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"time"

	"transaction-service/metrics"
	"transaction-service/models"

	_ "github.com/lib/pq"
	"go.uber.org/zap"
)

var (
	ErrTransactionNotFound = errors.New("transaction not found")
)

type TransactionRepository struct {
	db     *sql.DB
	logger *zap.Logger
}

type TransactionFilters struct {
	UserID   string
	Type     string
	Category string
}

func NewPostgresConnection(databaseURL string) (*sql.DB, error) {
	db, err := sql.Open("postgres", databaseURL)
	if err != nil {
		return nil, err
	}

	// Configurações de pool
	db.SetMaxOpenConns(25)
	db.SetMaxIdleConns(5)
	db.SetConnMaxLifetime(5 * time.Minute)

	// Testa conexão
	if err := db.Ping(); err != nil {
		return nil, err
	}

	return db, nil
}

func NewTransactionRepository(db *sql.DB, logger *zap.Logger) *TransactionRepository {
	return &TransactionRepository{
		db:     db,
		logger: logger,
	}
}

// Create cria uma nova transação
func (r *TransactionRepository) Create(ctx context.Context, transaction *models.Transaction) error {
	start := time.Now()
	defer func() {
		metrics.DatabaseQueryDuration.WithLabelValues("insert_transaction").Observe(time.Since(start).Seconds())
	}()

	query := `
		INSERT INTO transactions (id, user_id, description, amount, category, type, date, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
	`

	_, err := r.db.ExecContext(ctx, query,
		transaction.ID,
		transaction.UserID,
		transaction.Description,
		transaction.Amount,
		transaction.Category,
		transaction.Type,
		transaction.Date,
		transaction.CreatedAt,
		transaction.UpdatedAt,
	)

	if err != nil {
		r.logger.Error("failed to create transaction",
			zap.Error(err),
			zap.String("transaction_id", transaction.ID),
			zap.String("user_id", transaction.UserID),
		)
		return err
	}

	// Atualiza métrica de valor
	metrics.TransactionAmount.WithLabelValues(transaction.Type).Observe(transaction.Amount)

	return nil
}

// List lista transações com filtros e paginação
func (r *TransactionRepository) List(ctx context.Context, filters TransactionFilters, page, pageSize int) ([]*models.Transaction, int, error) {
	start := time.Now()
	defer func() {
		metrics.DatabaseQueryDuration.WithLabelValues("select_transactions").Observe(time.Since(start).Seconds())
	}()

	// Query base
	query := `
		SELECT id, user_id, description, amount, category, type, date, created_at, updated_at
		FROM transactions
		WHERE user_id = $1
	`
	args := []interface{}{filters.UserID}
	argCount := 1

	// Aplica filtros opcionais
	if filters.Type != "" {
		argCount++
		query += ` AND type = $` + fmt.Sprintf("%d", argCount)
		args = append(args, filters.Type)
	}

	if filters.Category != "" {
		argCount++
		query += ` AND category = $` + fmt.Sprintf("%d", argCount)
		args = append(args, filters.Category)
	}

	// Ordena por data mais recente
	query += ` ORDER BY date DESC, created_at DESC`

	// Paginação
	offset := (page - 1) * pageSize
	argCount++
	query += ` LIMIT $` + fmt.Sprintf("%d", argCount)
	args = append(args, pageSize)

	argCount++
	query += ` OFFSET $` + fmt.Sprintf("%d", argCount)
	args = append(args, offset)

	// Executa query
	rows, err := r.db.QueryContext(ctx, query, args...)
	if err != nil {
		r.logger.Error("failed to list transactions",
			zap.Error(err),
			zap.String("user_id", filters.UserID),
		)
		return nil, 0, err
	}
	defer rows.Close()

	// Processa resultados
	transactions := []*models.Transaction{}
	for rows.Next() {
		t := &models.Transaction{}
		err := rows.Scan(
			&t.ID,
			&t.UserID,
			&t.Description,
			&t.Amount,
			&t.Category,
			&t.Type,
			&t.Date,
			&t.CreatedAt,
			&t.UpdatedAt,
		)
		if err != nil {
			r.logger.Error("failed to scan transaction", zap.Error(err))
			continue
		}
		transactions = append(transactions, t)
	}

	// Conta total de registros
	countQuery := `
		SELECT COUNT(*)
		FROM transactions
		WHERE user_id = $1
	`
	countArgs := []interface{}{filters.UserID}

	if filters.Type != "" {
		countQuery += ` AND type = $2`
		countArgs = append(countArgs, filters.Type)
	}

	var total int
	err = r.db.QueryRowContext(ctx, countQuery, countArgs...).Scan(&total)
	if err != nil {
		r.logger.Error("failed to count transactions", zap.Error(err))
		return transactions, 0, err
	}

	return transactions, total, nil
}

// FindByID busca uma transação por ID
func (r *TransactionRepository) FindByID(ctx context.Context, id, userID string) (*models.Transaction, error) {
	start := time.Now()
	defer func() {
		metrics.DatabaseQueryDuration.WithLabelValues("select_transaction_by_id").Observe(time.Since(start).Seconds())
	}()

	query := `
		SELECT id, user_id, description, amount, category, type, date, created_at, updated_at
		FROM transactions
		WHERE id = $1 AND user_id = $2
	`

	transaction := &models.Transaction{}
	err := r.db.QueryRowContext(ctx, query, id, userID).Scan(
		&transaction.ID,
		&transaction.UserID,
		&transaction.Description,
		&transaction.Amount,
		&transaction.Category,
		&transaction.Type,
		&transaction.Date,
		&transaction.CreatedAt,
		&transaction.UpdatedAt,
	)

	if err == sql.ErrNoRows {
		return nil, ErrTransactionNotFound
	}

	if err != nil {
		r.logger.Error("failed to find transaction",
			zap.Error(err),
			zap.String("id", id),
			zap.String("user_id", userID),
		)
		return nil, err
	}

	return transaction, nil
}

// Update atualiza uma transação
func (r *TransactionRepository) Update(ctx context.Context, transaction *models.Transaction) error {
	start := time.Now()
	defer func() {
		metrics.DatabaseQueryDuration.WithLabelValues("update_transaction").Observe(time.Since(start).Seconds())
	}()

	query := `
		UPDATE transactions
		SET description = $1, amount = $2, category = $3, updated_at = $4
		WHERE id = $5 AND user_id = $6
	`

	result, err := r.db.ExecContext(ctx, query,
		transaction.Description,
		transaction.Amount,
		transaction.Category,
		transaction.UpdatedAt,
		transaction.ID,
		transaction.UserID,
	)

	if err != nil {
		r.logger.Error("failed to update transaction",
			zap.Error(err),
			zap.String("id", transaction.ID),
		)
		return err
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return err
	}

	if rowsAffected == 0 {
		return ErrTransactionNotFound
	}

	return nil
}

// Delete deleta uma transação
func (r *TransactionRepository) Delete(ctx context.Context, id, userID string) error {
	start := time.Now()
	defer func() {
		metrics.DatabaseQueryDuration.WithLabelValues("delete_transaction").Observe(time.Since(start).Seconds())
	}()

	query := `DELETE FROM transactions WHERE id = $1 AND user_id = $2`

	result, err := r.db.ExecContext(ctx, query, id, userID)
	if err != nil {
		r.logger.Error("failed to delete transaction",
			zap.Error(err),
			zap.String("id", id),
			zap.String("user_id", userID),
		)
		return err
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return err
	}

	if rowsAffected == 0 {
		return ErrTransactionNotFound
	}

	return nil
}

// GetStats retorna estatísticas das transações do usuário
func (r *TransactionRepository) GetStats(ctx context.Context, userID string) (*models.TransactionStats, error) {
	start := time.Now()
	defer func() {
		metrics.DatabaseQueryDuration.WithLabelValues("select_transaction_stats").Observe(time.Since(start).Seconds())
	}()

	stats := &models.TransactionStats{
		ByCategory: make(map[string]float64),
	}

	// Total de receitas e despesas
	query := `
		SELECT 
			COALESCE(SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END), 0) as total_income,
			COALESCE(SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END), 0) as total_expenses,
			COUNT(*) as total_count
		FROM transactions
		WHERE user_id = $1
	`

	err := r.db.QueryRowContext(ctx, query, userID).Scan(
		&stats.TotalIncome,
		&stats.TotalExpenses,
		&stats.TotalCount,
	)

	if err != nil {
		r.logger.Error("failed to get transaction stats",
			zap.Error(err),
			zap.String("user_id", userID),
		)
		return nil, err
	}

	stats.Balance = stats.TotalIncome - stats.TotalExpenses

	// Estatísticas por categoria
	categoryQuery := `
		SELECT category, SUM(amount) as total
		FROM transactions
		WHERE user_id = $1
		GROUP BY category
		ORDER BY total DESC
	`

	rows, err := r.db.QueryContext(ctx, categoryQuery, userID)
	if err != nil {
		r.logger.Error("failed to get category stats", zap.Error(err))
		return stats, nil // Retorna stats parcial
	}
	defer rows.Close()

	for rows.Next() {
		var category string
		var total float64
		if err := rows.Scan(&category, &total); err != nil {
			continue
		}
		stats.ByCategory[category] = total
	}

	// Última transação
	lastQuery := `
		SELECT id, user_id, description, amount, category, type, date, created_at, updated_at
		FROM transactions
		WHERE user_id = $1
		ORDER BY date DESC, created_at DESC
		LIMIT 1
	`

	lastTransaction := &models.Transaction{}
	err = r.db.QueryRowContext(ctx, lastQuery, userID).Scan(
		&lastTransaction.ID,
		&lastTransaction.UserID,
		&lastTransaction.Description,
		&lastTransaction.Amount,
		&lastTransaction.Category,
		&lastTransaction.Type,
		&lastTransaction.Date,
		&lastTransaction.CreatedAt,
		&lastTransaction.UpdatedAt,
	)

	if err == nil {
		stats.LastTransaction = lastTransaction
	} else if err != sql.ErrNoRows {
		r.logger.Error("failed to get last transaction", zap.Error(err))
	}

	return stats, nil
}
