package api

import (
	"errors"
	"testing"

	"example.com/billing/authz"
	"example.com/billing/customers"
)

func newAPI() CustomerAPI {
	return CustomerAPI{Customers: customers.NewStore(customers.Customer{ID: "c1", Name: "Ada"})}
}

func TestOwnerReadsOwnCustomer(t *testing.T) {
	dto, err := newAPI().GetCustomer(authz.Principal{CustomerID: "c1"}, "c1")
	if err != nil || dto.Name != "Ada" {
		t.Fatalf("GetCustomer = %+v, %v; want Ada, nil", dto, err)
	}
}

func TestOtherCustomerIsForbidden(t *testing.T) {
	_, err := newAPI().GetCustomer(authz.Principal{CustomerID: "c2"}, "c1")
	if !errors.Is(err, authz.ErrForbidden) {
		t.Fatalf("err = %v, want ErrForbidden", err)
	}
}
