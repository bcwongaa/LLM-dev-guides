// Package billing renders billing documents.
package billing

import "fmt"

// money renders integer minor units as "<CUR> <major>.<minor>", always with two decimals.
func money(amountMinor int64, currency string) string {
	sign := ""
	if amountMinor < 0 {
		sign = "-"
		amountMinor = -amountMinor
	}
	return fmt.Sprintf("%s %s%d.%02d", currency, sign, amountMinor/100, amountMinor%100)
}
