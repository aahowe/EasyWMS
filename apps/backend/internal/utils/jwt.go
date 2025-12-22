package utils

import (
	"errors"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

// Claims JWT声明结构
type Claims struct {
	UserID   int64  `json:"user_id"`
	Username string `json:"username"`
	RoleCode string `json:"role_code"`
	jwt.RegisteredClaims
}

// GenerateToken 生成JWT令牌
func GenerateToken(userID int64, username, roleCode, secret string, expireHours int) (string, error) {
	claims := Claims{
		UserID:   userID,
		Username: username,
		RoleCode: roleCode,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(time.Duration(expireHours) * time.Hour)),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
			NotBefore: jwt.NewNumericDate(time.Now()),
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString([]byte(secret))
}

// ParseToken 解析JWT令牌
func ParseToken(tokenString, secret string) (*Claims, error) {
	token, err := jwt.ParseWithClaims(tokenString, &Claims{}, func(token *jwt.Token) (interface{}, error) {
		return []byte(secret), nil
	})

	if err != nil {
		return nil, err
	}

	if claims, ok := token.Claims.(*Claims); ok && token.Valid {
		return claims, nil
	}

	return nil, errors.New("invalid token")
}
