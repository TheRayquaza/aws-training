package main

import (
	"log"
	"back/src/api"
	"back/src/config"
	"back/src/data/database"
)

func main() {
	cfg := config.LoadConfig()

	// Connect to Redis
	if err := database.InitRedis(cfg.RedisAddr); err != nil {
		log.Fatalf("Fatal: Could not connect to Redis at %s: %v", cfg.RedisAddr, err)
	}
	log.Printf("Connected to Redis at %s", cfg.RedisAddr)

	r := api.SetupRouter()
	
	log.Printf("Server starting on port %s", cfg.ServerPort)
	if err := r.Run(":" + cfg.ServerPort); err != nil {
		log.Fatal(err)
	}
}
