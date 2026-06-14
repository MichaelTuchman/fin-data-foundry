# Finance Foundry

A metadata-driven framework for normalizing inconsistent financial transaction data across multiple institutions and over time.

## Why this exists

Financial data is inconsistent in two fundamental ways:

### 1. Across sources

Different banks and financial institutions:

- Use different CSV formats
- Change column layouts over time
- Represent the same concepts differently
- Do not share a common schema

### 2. Over time within a single source

Even a single institution is not stable:

- Export formats evolve
- Columns are added, removed, or reordered
- Historical “catch-up” files appear later
- Schema assumptions silently break

This leads to a recurring failure mode:

> “The data loads successfully, but I don’t trust the result — and I can’t explain why.”

Finance Foundry exists to eliminate that uncertainty.

---

## What this system does

Finance Foundry separates:

- **data ingestion** (preserve raw structure)
- **data interpretation** (apply metadata-driven rules)

Raw files are never modified. Instead, metadata defines how they are transformed into a canonical transaction model.

This allows inconsistent financial data to be normalized without per-source ETL logic.

---

## Core principle

> All transformations must be traceable, and no row may disappear without explanation.

This is enforced through a staged pipeline:

```
raw_csv
  → raw_boundary
  → file_context
  → layout_match
  → canon_long
  → canon_wide
  → trans_analy
```

Each stage is designed to make failures visible rather than hidden.

---

## System guarantees

- Row preservation across all transformation stages
- Explicit file identity and time coverage resolution
- Metadata-driven schema selection (no hardcoded parsing logic per bank)
- Deterministic transformations
- Observable failure points at each stage

---

## Use cases

This system is designed for working with inconsistent financial data across multiple sources and over time.

Even within a single institution, formats evolve continuously.

### Personal Finance Aggregation

Combine transaction exports from multiple banks:

- Wells Fargo, Chase, Amex, etc.
- Inconsistent formats and column layouts
- Output: a single unified transaction table

---

### Financial Analysis & Reporting

Prepare structured datasets for:

- spending analysis
- budgeting and reconciliation
- BI dashboards and analytics tools

Instead of manual cleaning, structure is defined once in metadata.

---

### Schema-on-Read Data Engineering

Support evolving file formats without rewriting pipelines:

- multiple layouts per source system
- schema changes over time
- no per-bank ETL code paths

Works well with:

- AWS Athena / Trino / Presto
- data lake architectures

---

### Fintech Prototyping

Build financial tools without API dependencies:

- ingest exported bank data directly
- normalize into a canonical schema
- rapidly prototype analytics and aggregation systems

---

### Evolving Data Formats

Banks frequently change export formats.

Finance Foundry handles this by:

- supporting multiple layouts per source
- applying effective-date-based schema selection
- preserving backward compatibility

---

## Design influences

This system is influenced by principles from:

- clinical programming (traceability of derived values)
- actuarial modeling (conservation of quantities across transformations)

These domains share a common requirement:

> transformations must be explainable, auditable, and reproducible.

---

## Current implementation

The reference implementation uses:

- AWS S3 for storage
- AWS Athena for query execution
- SQL-based metadata-driven transformations

The architecture is platform-agnostic and can be adapted to other environments.

---

## Future directions

Potential extensions include:

- merchant classification
- transaction categorization
- data enrichment layers
- reconciliation across accounts and institutions
