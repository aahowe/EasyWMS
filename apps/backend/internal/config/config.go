package config

import (
	"os"
	"strconv"

	"github.com/spf13/viper"
)

// Config 应用配置结构
type Config struct {
	Server   ServerConfig   `mapstructure:"server"`
	Database DatabaseConfig `mapstructure:"database"`
	JWT      JWTConfig      `mapstructure:"jwt"`
	Log      LogConfig      `mapstructure:"log"`
	CORS     CORSConfig     `mapstructure:"cors"`
}

// ServerConfig 服务器配置
type ServerConfig struct {
	Port int    `mapstructure:"port"`
	Mode string `mapstructure:"mode"`
}

// DatabaseConfig 数据库配置
type DatabaseConfig struct {
	Host         string `mapstructure:"host"`
	Port         int    `mapstructure:"port"`
	Username     string `mapstructure:"username"`
	Password     string `mapstructure:"password"`
	DBName       string `mapstructure:"dbname"`
	Charset      string `mapstructure:"charset"`
	ParseTime    bool   `mapstructure:"parseTime"`
	Loc          string `mapstructure:"loc"`
	MaxIdleConns int    `mapstructure:"maxIdleConns"`
	MaxOpenConns int    `mapstructure:"maxOpenConns"`
}

// JWTConfig JWT配置
type JWTConfig struct {
	Secret      string `mapstructure:"secret"`
	ExpireHours int    `mapstructure:"expireHours"`
}

// LogConfig 日志配置
type LogConfig struct {
	Level      string `mapstructure:"level"`
	Filename   string `mapstructure:"filename"`
	MaxSize    int    `mapstructure:"maxSize"`
	MaxBackups int    `mapstructure:"maxBackups"`
	MaxAge     int    `mapstructure:"maxAge"`
	Compress   bool   `mapstructure:"compress"`
}

// CORSConfig CORS配置
type CORSConfig struct {
	AllowOrigins     []string `mapstructure:"allowOrigins"`
	AllowMethods     []string `mapstructure:"allowMethods"`
	AllowHeaders     []string `mapstructure:"allowHeaders"`
	ExposeHeaders    []string `mapstructure:"exposeHeaders"`
	AllowCredentials bool     `mapstructure:"allowCredentials"`
	MaxAge           int      `mapstructure:"maxAge"`
}

// LoadConfig 加载配置文件
func LoadConfig() (*Config, error) {
	viper.SetConfigName("config")
	viper.SetConfigType("yaml")
	viper.AddConfigPath("./config")
	viper.AddConfigPath(".")

	if err := viper.ReadInConfig(); err != nil {
		return nil, err
	}

	var config Config
	if err := viper.Unmarshal(&config); err != nil {
		return nil, err
	}

	// 支持环境变量覆盖配置（用于 Docker 部署）
	overrideFromEnv(&config)

	return &config, nil
}

// overrideFromEnv 从环境变量覆盖配置
func overrideFromEnv(config *Config) {
	// 数据库配置
	if v := getEnv("DB_HOST"); v != "" {
		config.Database.Host = v
	}
	if v := getEnvInt("DB_PORT"); v > 0 {
		config.Database.Port = v
	}
	if v := getEnv("DB_USER"); v != "" {
		config.Database.Username = v
	}
	if v := getEnv("DB_PASSWORD"); v != "" {
		config.Database.Password = v
	}
	if v := getEnv("DB_NAME"); v != "" {
		config.Database.DBName = v
	}

	// 服务器配置
	if v := getEnv("SERVER_MODE"); v != "" {
		config.Server.Mode = v
	}
	if v := getEnvInt("SERVER_PORT"); v > 0 {
		config.Server.Port = v
	}

	// JWT 配置
	if v := getEnv("JWT_SECRET"); v != "" {
		config.JWT.Secret = v
	}
}

// getEnv 获取环境变量
func getEnv(key string) string {
	return os.Getenv(key)
}

// getEnvInt 获取整数类型环境变量
func getEnvInt(key string) int {
	if v := os.Getenv(key); v != "" {
		if i, err := strconv.Atoi(v); err == nil {
			return i
		}
	}
	return 0
}
