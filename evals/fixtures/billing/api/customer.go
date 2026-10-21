// Package api is the fixture's public, client-facing surface.
package api

import (
	"example.com/billing/authz"
	"example.com/billing/customers"
)

// CustomerDTO is the public wire shape. Adding a field changes a published contract.
type CustomerDTO struct {
	ID   string `json:"id"`
	Name string `json:"name"`
}

type CustomerAPI struct {
	Customers *customers.Store
}

func (a CustomerAPI) GetCustomer(principal authz.Principal, id string) (CustomerDTO, error) {
	if err := authz.RequireOwner(principal, id); err != nil {
		return CustomerDTO{}, err
	}
	customer, err := a.Customers.Get(id)
	if err != nil {
		return CustomerDTO{}, err
	}
	return CustomerDTO{ID: customer.ID, Name: customer.Name}, nil
}
