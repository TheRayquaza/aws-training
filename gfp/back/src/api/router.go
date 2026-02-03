package api

import (
	"log"
	"back/src/api/controllers"
	"github.com/gin-gonic/gin"
)

func SetupRouter() *gin.Engine {
	r := gin.Default()

	// CORS Middleware
	r.Use(func(c *gin.Context) {
		c.Writer.Header().Set("Access-Control-Allow-Origin", "*")
		c.Writer.Header().Set("Access-Control-Allow-Methods", "POST, GET, OPTIONS, PUT, DELETE")
		c.Writer.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")
		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}
		c.Next()
	})

	api := r.Group("/api")
	{
		// Internal Protein CRUD
		api.GET("/proteins", controllers.GetProteins)
		api.POST("/proteins", controllers.CreateProtein)
		api.PUT("/proteins/:id", controllers.UpdateProtein)
		api.DELETE("/proteins/:id", controllers.DeleteProtein)

		// External PDB Tools
		api.GET("/pdb", controllers.ProxyPDB)
		api.GET("/search", controllers.SearchPDB)
	}

	r.GET("/health", func(c *gin.Context) {
		log.Println("Health check endpoint called")
		c.JSON(200, gin.H{"status": "UP"})
	})

	return r
}
