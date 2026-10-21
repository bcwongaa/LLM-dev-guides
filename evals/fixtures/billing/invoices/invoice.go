// Package invoices holds invoice records.
package invoices

type Status string

const (
	Draft Status = "draft"
	Paid  Status = "paid"
	Void  Status = "void"
)

// Invoice amounts are integer minor units (cents) of Currency.
type Invoice struct {
	ID          string
	CustomerID  string
	AmountMinor int64
	Currency    string
	Status      Status
}

type Store struct {
	all []Invoice
}

func NewStore(seed ...Invoice) *Store {
	return &Store{all: seed}
}

func (s *Store) ForCustomer(customerID string) []Invoice {
	var customerInvoices []Invoice
	for _, invoice := range s.all {
		if invoice.CustomerID == customerID {
			customerInvoices = append(customerInvoices, invoice)
		}
	}
	return customerInvoices
}
