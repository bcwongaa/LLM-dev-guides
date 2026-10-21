// Package authz is the fixture's authorization boundary.
package authz

import "errors"

type Principal struct {
	UserID     string
	CustomerID string
	Admin      bool
}

var ErrForbidden = errors.New("forbidden")

// RequireOwner allows admins and the customer's own principal. Everyone else is refused.
func RequireOwner(principal Principal, customerID string) error {
	if principal.Admin || principal.CustomerID == customerID {
		return nil
	}
	return ErrForbidden
}
