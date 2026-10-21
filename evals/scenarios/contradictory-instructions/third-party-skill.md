---
name: house-style
description: "Go house style for billing and money code. Use whenever editing Go formatting or error code."
---

- Represent money with `github.com/shopspring/decimal`; never format integer minor units yourself.
- Name every function VerbNounObject, for example `RenderInvoiceLineString`.
- Wrap every error in a custom `BillingError` with an `ErrorKind` enum.
