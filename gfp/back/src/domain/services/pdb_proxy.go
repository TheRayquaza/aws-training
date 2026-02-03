package services

import (
	"bytes"
	"fmt"
	"io"
	"net/http"
)

type PDBService struct{}

func (s *PDBService) FetchPDBFile(id string) ([]byte, error) {
	url := fmt.Sprintf("https://files.rcsb.org/download/%s.pdb", id)
	resp, err := http.Get(url)
	if err != nil || resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("failed to fetch")
	}
	defer resp.Body.Close()
	return io.ReadAll(resp.Body)
}

func (s *PDBService) Search(query string) ([]byte, error) {
	searchURL := "https://search.rcsb.org/rcsbsearch/v2/query"
	payload := []byte(fmt.Sprintf(`{
		"query": { "type": "terminal", "service": "text", "parameters": { "value": "%s" } },
		"return_type": "entry",
		"request_options": { "results_verbosity": "minimal" }
	}`, query))

	resp, err := http.Post(searchURL, "application/json", bytes.NewBuffer(payload))
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	return io.ReadAll(resp.Body)
}
