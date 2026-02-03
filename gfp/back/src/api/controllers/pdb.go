package controllers

import (
	"net/http"
	"back/src/domain/services"
	"github.com/gin-gonic/gin"
)

var pdbService = &services.PDBService{}

func ProxyPDB(c *gin.Context) {
	pdbID := c.Query("id")
	if pdbID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "PDB ID is required"})
		return
	}

	data, err := pdbService.FetchPDBFile(pdbID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "PDB file not found"})
		return
	}

	c.Data(http.StatusOK, "text/plain", data)
}

func SearchPDB(c *gin.Context) {
	query := c.Query("q")
	if query == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Search query is required"})
		return
	}

	results, err := pdbService.Search(query)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.Data(http.StatusOK, "application/json", results)
}
