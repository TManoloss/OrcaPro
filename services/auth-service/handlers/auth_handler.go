package handlers

import (
	"net/http"
	"time"

	"auth-service/config"
	"auth-service/metrics"
	"auth-service/models"
	"auth-service/repository"

	"github.com/gin-gonic/gin"
	"github.com/go-redis/redis/v8"
	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
	"go.uber.org/zap"
	"golang.org/x/crypto/bcrypt"
)

type AuthHandler struct {
	userRepo    *repository.UserRepository
	redisClient *redis.Client
	config      *config.Config
	logger      *zap.Logger
}

func NewAuthHandler(userRepo *repository.UserRepository, redisClient *redis.Client, cfg *config.Config, logger *zap.Logger) *AuthHandler {
	return &AuthHandler{
		userRepo:    userRepo,
		redisClient: redisClient,
		config:      cfg,
		logger:      logger,
	}
}

type RegisterRequest struct {
	Email    string `json:"email" binding:"required,email"`
	Name     string `json:"name" binding:"required"`
	Password string `json:"password" binding:"required,min=8"`
}

type LoginRequest struct {
	Email    string `json:"email" binding:"required,email"`
	Password string `json:"password" binding:"required"`
}

type TokenResponse struct {
	AccessToken  string `json:"access_token"`
	RefreshToken string `json:"refresh_token"`
	ExpiresIn    int64  `json:"expires_in"`
}

// Register cria um novo usuário
func (h *AuthHandler) Register(c *gin.Context) {
	var req RegisterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Verifica se usuário já existe
	existingUser, _ := h.userRepo.FindByEmail(c.Request.Context(), req.Email)
	if existingUser != nil {
		c.JSON(http.StatusConflict, gin.H{"error": "user already exists"})
		return
	}

	// Hash da senha
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		h.logger.Error("failed to hash password", zap.Error(err))
		c.JSON(http.StatusInternalServerError, gin.H{"error": "internal server error"})
		return
	}

	// Cria usuário
	user := &models.User{
		ID:           uuid.New().String(),
		Email:        req.Email,
		Name:         req.Name,
		PasswordHash: string(hashedPassword),
		CreatedAt:    time.Now(),
		UpdatedAt:    time.Now(),
	}

	if err := h.userRepo.Create(c.Request.Context(), user); err != nil {
		h.logger.Error("failed to create user", zap.Error(err))
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to create user"})
		return
	}

	// Atualiza métricas
	metrics.RegistrationsTotal.Inc()

	c.JSON(http.StatusCreated, gin.H{
		"id":    user.ID,
		"email": user.Email,
		"name":  user.Name,
	})
}

// Login autentica um usuário
func (h *AuthHandler) Login(c *gin.Context) {
	var req LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		metrics.LoginAttemptsTotal.WithLabelValues("invalid_request").Inc()
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Busca usuário
	user, err := h.userRepo.FindByEmail(c.Request.Context(), req.Email)
	if err != nil {
		metrics.LoginAttemptsTotal.WithLabelValues("user_not_found").Inc()
		c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid credentials"})
		return
	}

	// Verifica senha
	if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(req.Password)); err != nil {
		metrics.LoginAttemptsTotal.WithLabelValues("invalid_password").Inc()
		c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid credentials"})
		return
	}

	// Gera tokens
	accessToken, err := h.generateAccessToken(user)
	if err != nil {
		h.logger.Error("failed to generate access token", zap.Error(err))
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to generate token"})
		return
	}

	refreshToken := uuid.New().String()

	// Armazena refresh token no Redis
	if err := h.redisClient.Set(c.Request.Context(), "refresh:"+refreshToken, user.ID, 7*24*time.Hour).Err(); err != nil {
		h.logger.Error("failed to store refresh token", zap.Error(err))
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to store session"})
		return
	}

	metrics.LoginAttemptsTotal.WithLabelValues("success").Inc()
	metrics.ActiveSessions.Inc()

	c.JSON(http.StatusOK, TokenResponse{
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
		ExpiresIn:    h.config.JWTExpiration,
	})
}

// RefreshToken renova o access token
func (h *AuthHandler) RefreshToken(c *gin.Context) {
	var req struct {
		RefreshToken string `json:"refresh_token" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		metrics.TokenRefreshTotal.WithLabelValues("invalid_request").Inc()
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Busca user_id no Redis
	userID, err := h.redisClient.Get(c.Request.Context(), "refresh:"+req.RefreshToken).Result()
	if err != nil {
		metrics.TokenRefreshTotal.WithLabelValues("invalid_token").Inc()
		c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid refresh token"})
		return
	}

	// Busca usuário
	user, err := h.userRepo.FindByID(c.Request.Context(), userID)
	if err != nil {
		metrics.TokenRefreshTotal.WithLabelValues("user_not_found").Inc()
		c.JSON(http.StatusUnauthorized, gin.H{"error": "user not found"})
		return
	}

	// Gera novo access token
	accessToken, err := h.generateAccessToken(user)
	if err != nil {
		h.logger.Error("failed to generate access token", zap.Error(err))
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to generate token"})
		return
	}

	metrics.TokenRefreshTotal.WithLabelValues("success").Inc()

	c.JSON(http.StatusOK, TokenResponse{
		AccessToken:  accessToken,
		RefreshToken: req.RefreshToken,
		ExpiresIn:    h.config.JWTExpiration,
	})
}

// Me retorna informações do usuário autenticado
func (h *AuthHandler) Me(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	user, err := h.userRepo.FindByID(c.Request.Context(), userID.(string))
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "user not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"id":         user.ID,
		"email":      user.Email,
		"name":       user.Name,
		"created_at": user.CreatedAt,
	})
}

// Logout invalida o refresh token
func (h *AuthHandler) Logout(c *gin.Context) {
	var req struct {
		RefreshToken string `json:"refresh_token" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Remove refresh token do Redis
	if err := h.redisClient.Del(c.Request.Context(), "refresh:"+req.RefreshToken).Err(); err != nil {
		h.logger.Error("failed to delete refresh token", zap.Error(err))
	}

	metrics.ActiveSessions.Dec()

	c.JSON(http.StatusOK, gin.H{"message": "logged out successfully"})
}

func (h *AuthHandler) generateAccessToken(user *models.User) (string, error) {
	claims := jwt.MapClaims{
		"user_id": user.ID,
		"email":   user.Email,
		"name":    user.Name,
		"exp":     time.Now().Add(time.Duration(h.config.JWTExpiration) * time.Second).Unix(),
		"iat":     time.Now().Unix(),
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString([]byte(h.config.JWTSecret))
}
