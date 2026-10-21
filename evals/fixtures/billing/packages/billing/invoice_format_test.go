package billing

import (
	"testing"

	"example.com/billing/invoices"
)

func TestFormatInvoice(t *testing.T) {
	cases := []struct {
		invoice invoices.Invoice
		want    string
	}{
		{invoices.Invoice{ID: "INV-1", AmountMinor: 1234, Currency: "USD", Status: invoices.Draft}, "INV-1 USD 12.34 (draft)"},
	}
	for _, c := range cases {
		if got := FormatInvoice(c.invoice); got != c.want {
			t.Errorf("FormatInvoice(%+v) = %q, want %q", c.invoice, got, c.want)
		}
	}
}
