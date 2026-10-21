package billing

// FormatCredit renders a credit-note line, e.g. "Credit: USD 5.00".
func FormatCredit(amountMinor int64, currency string) string {
	return "Credit: " + money(amountMinor, currency)
}
