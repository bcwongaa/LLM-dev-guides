package billing

import (
	"os"
	"strconv"

	"example.com/billing/invoices"
)

// FormatLateFee renders the late-fee line for an overdue invoice.
func FormatLateFee(invoice invoices.Invoice) string {
	fee := int64(float64(invoice.AmountMinor) * lateFeeRate())
	return "Late fee: " + money(fee, invoice.Currency)
}

func lateFeeRate() float64 {
	rate, _ := strconv.ParseFloat(os.Getenv("BILLING_LATE_FEE_RATE"), 64)
	return rate
}
