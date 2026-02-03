package services

import (
	"encoding/json"
	"fmt"
	"time"

	"back/src/data/database"
	"back/src/data/models"
)

type ProteinService struct{}

func (s *ProteinService) GetAll() ([]models.Protein, error) {
	keys, err := database.RDB.Keys(database.Ctx, "protein:*").Result()
	if err != nil {
		return nil, err
	}

	proteins := []models.Protein{}
	for _, key := range keys {
		val, _ := database.RDB.Get(database.Ctx, key).Result()
		var p models.Protein
		json.Unmarshal([]byte(val), &p)
		proteins = append(proteins, p)
	}
	return proteins, nil
}

func (s *ProteinService) Create(p *models.Protein) error {
	p.CreatedAt = time.Now()
	if p.ID == "" {
		p.ID = fmt.Sprintf("%d", time.Now().UnixNano())
	}
	data, _ := json.Marshal(p)
	return database.RDB.Set(database.Ctx, "protein:"+p.ID, data, 0).Err()
}

func (s *ProteinService) Update(id string, p *models.Protein) error {
	exists, _ := database.RDB.Exists(database.Ctx, "protein:"+id).Result()
	if exists == 0 {
		return fmt.Errorf("not found")
	}
	p.ID = id
	data, _ := json.Marshal(p)
	return database.RDB.Set(database.Ctx, "protein:"+id, data, 0).Err()
}

func (s *ProteinService) Delete(id string) error {
	return database.RDB.Del(database.Ctx, "protein:"+id).Err()
}
