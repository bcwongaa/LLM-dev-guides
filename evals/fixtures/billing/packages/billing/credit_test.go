package billing

import "testing"

func TestFormatCredit(t *testing.T) {
	cases := []struct {
		amountMinor int64
		want        string
	}{
		{500, "Credit: USD 5.00"},
		{1205, "Credit: USD 12.05"},
		{-250, "Credit: USD -2.50"},
	}
	for _, c := range cases {
		if got := FormatCredit(c.amountMinor, "USD"); got != c.want {
			t.Errorf("FormatCredit(%d) = %q, want %q", c.amountMinor, got, c.want)
		}
	}
}
