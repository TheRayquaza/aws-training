package config

import (
	"os"
)

type Config struct {
	RedisAddr string
	ServerPort string
}

func LoadConfig() *Config {
	return &Config{
		RedisAddr:  getEnv("REDIS_ADDR", "localhost:6379"),
		ServerPort: getEnv("SERVER_PORT", "8080"),
	}
}

func getEnv(key, fallback string) string {
	if value, ok := os.LookupEnv(key); ok {
		return value
	}
	return fallback
}
