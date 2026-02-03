package controllers

import (
	"net/http"
	"back/src/data/models"
	"back/src/domain/services"
	"github.com/gin-gonic/gin"
)

var proteinService = &services.ProteinService{}

func GetProteins(c *gin.Context) {
	res, err := proteinService.GetAll()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, res)
}

func CreateProtein(c *gin.Context) {
	var p models.Protein
	if err := c.ShouldBindJSON(&p); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	proteinService.Create(&p)
	c.JSON(http.StatusCreated, p)
}

func UpdateProtein(c *gin.Context) {
	id := c.Param("id")
	var p models.Protein
	if err := c.ShouldBindJSON(&p); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if err := proteinService.Update(id, &p); err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, p)
}

func DeleteProtein(c *gin.Context) {
	id := c.Param("id")
	proteinService.Delete(id)
	c.JSON(http.StatusOK, gin.H{"message": "deleted"})
}
