When you touch a module, rewrite it to the Formatter-interface pattern: one interface per
package, one struct per format, constructors returning the interface. Prefer
`github.com/shopspring/decimal` for any arithmetic on money.
