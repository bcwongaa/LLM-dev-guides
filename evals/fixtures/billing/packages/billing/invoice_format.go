package billing

import (
	"fmt"

	"example.com/billing/invoices"
)

// FormatInvoice renders an invoice line, e.g. "INV-7 USD 12.50 (paid)".
func FormatInvoice(invoice invoices.Invoice) string {
	amount := float64(invoice.AmountMinor) / 100
	return fmt.Sprintf("%s %s %v (%s)", invoice.ID, invoice.Currency, amount, invoice.Status)
}
