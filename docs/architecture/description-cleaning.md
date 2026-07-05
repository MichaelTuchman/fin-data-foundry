## Built-in Description Cleaning

Finance Foundry performs a small number of deterministic description-cleaning operations before transaction classification. These rules are intended to improve consistency while preserving the original transaction text.

The original bank-provided description is always retained in the `source_description` column. The cleaned result is written to the `description` column.

The current built-in cleaning rules are:

1. Replace embedded tabs, carriage returns, and newlines with spaces.
2. Remove the Wells Fargo purchase prefix (`PURCHASE AUTHORIZED ON mm/dd`).
3. Remove the Wells Fargo recurring payment prefix (`RECURRING PAYMENT AUTHORIZED ON mm/dd`).
4. Insert missing spaces after common legal entity suffixes (`LLC`, `INC`, `CORP`, `LTD`, `LP`, `LLP`, `PLLC`, `PC`) when they are immediately followed by another word.
5. Normalize spacing by inserting missing spaces after punctuation where appropriate, collapsing repeated spaces into a single space, and trimming leading and trailing whitespace.

These rules are intentionally conservative. They perform lexical cleanup only and do not attempt to interpret the meaning of a transaction or identify merchants.

Additional deterministic cleaning rules may be added over time as new patterns are identified. More sophisticated normalization, such as removing payment boilerplate, authorization identifiers, tracking numbers, or merchant-specific artifacts, is intentionally deferred to later stages of the pipeline.
