// Package customers holds customer records.
package customers

import "errors"

type Customer struct {
	ID    string
	Name  string
	Email string
}

var ErrNotFound = errors.New("customer not found")

// Store is in memory; the fixture has no database.
type Store struct {
	byID map[string]Customer
}

func NewStore(seed ...Customer) *Store {
	store := &Store{byID: map[string]Customer{}}
	for _, customer := range seed {
		store.byID[customer.ID] = customer
	}
	return store
}

// Get returns the customer or ErrNotFound.
func (s *Store) Get(id string) (Customer, error) {
	customer, ok := s.byID[id]
	if !ok {
		return Customer{}, ErrNotFound
	}
	return customer, nil
}
