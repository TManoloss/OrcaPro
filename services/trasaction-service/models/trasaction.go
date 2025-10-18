package models

import "time"

type Transaction struct {
	ID          string    `json:"id" db:"id"`
	UserID      string    `json:"user_id" db:"user_id"`
	Description string    `json:"description" db:"description"`
	Amount      float64   `json:"amount" db:"amount"`
	Category    string    `json:"category" db:"category"`
	Type        string    `json:"type" db:"type"` // income or expense
	Date        time.Time `json:"date" db:"date"`
	CreatedAt   time.Time `json:"created_at" db:"created_at"`
	UpdatedAt   time.Time `json:"updated_at" db:"updated_at"`
}

type TransactionStats struct {
	TotalIncome    float64            `json:"total_income"`
	TotalExpenses  float64            `json:"total_expenses"`
	Balance        float64            `json:"balance"`
	TotalCount     int                `json:"total_count"`
	ByCategory     map[string]float64 `json:"by_category"`
	LastTransaction *Transaction      `json:"last_transaction,omitempty"`
}