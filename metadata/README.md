# Finance Foundry metadata source

These YAML files are the human-maintained metadata source.

- `accounts.yml`
- `layout_controls.yml`
- `layout_cols.yml`
- `transaction_type_rules.yml`

The generated Athena CSV metadata tables should be built from these files and should not be edited directly.

Migration notes:
- Duplicate `amx|gold|LAYOUT_A` rows from the pasted table were excluded because `amex|gold|LAYOUT_A` is the canonical account key in `accounts.yml` and `layout_controls.yml`.
- HTML-escaped pipe characters in pasted regular expressions were restored.
- The `PURCH_000` word-boundary pattern was restored as `\b(PURCHASE|POS PURCHASE|DEBIT PURCHASE)\b`.
