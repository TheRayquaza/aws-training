package models

import "time"

type Protein struct {
	ID          string    `json:"id"`
	Name        string    `json:"name"`          // e.g., "Hemoglobin"
	PdbID       string    `json:"pdb_id"`        // e.g., "1A3N"
	Description string    `json:"description"`
	CreatedAt   time.Time `json:"created_at"`
}
