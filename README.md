# Finance Foundry

A metadata-driven framework for harmonizing financial transaction data across multiple institutions and over time.

Financial data is difficult because inconsistency exists in two dimensions:

- Different institutions export data in different formats.
- The same institution changes formats over time.

As a result, combining transaction data across accounts often becomes a manual, fragile, and difficult-to-audit process.

Finance Foundry addresses this problem by separating **data ingestion** from **data interpretation**.

Raw files are preserved as-is. Metadata defines how those files should be interpreted and transformed into a canonical transaction model.

The name *Foundry* is intentional:

> A foundry transforms raw, unrefined material into consistent, usable forms.

Finance Foundry applies the same principle to financial data, transforming heterogeneous transaction exports into a unified, queryable dataset.

---

## Why this exists

Many financial data projects eventually run into the same questions:

> Why don't my numbers match?

> Why did my rows disappear?

> Which transformation changed this value?

Traditional pipelines often focus *merely* on producing outputs.

Finance Foundry focuses on producing outputs that remain _explainable_.

The goal is not simply to **transform data**, but to make every change traceable, observable, and reproducible.

---

## Core Principles

### Preserve Raw Data

Raw source files are never rewritten.

Interpretation occurs through metadata rather than modification of source data.

### Separate Structure from Meaning

The system separates:

- file ingestion
- layout identification
- schema interpretation
- analysis-ready modeling

This allows formats to evolve without requiring new code paths for every source.

### Make Failure Visible

Transformation failures should be observable and diagnosable.

The system is designed to answer questions such as:

> Where did my rows go?

> Which layout was selected?

> Why was this file interpreted this way?

### Preserve Row Identity

Rows should not silently disappear during transformation.

Row preservation is treated as a first-class invariant throughout the pipeline.

---

## Architecture

The reference implementation uses a staged transformation model:

```text
raw
    ↓
canonical
    ↓
analysis
    ↓
lexical cleanup
    ↓
typing
    ↓
semantic normalization
    ↓
export
```

### raw_boundary

Identifies source files and preserves file-level context.

### file_context

Derives:

- source system
- account identity
- file coverage period

from file structure and naming conventions.

### layout_match

Determines which layout definition applies to a file based on metadata and effective date ranges.

### canon_long

Normalizes heterogeneous source columns into a metadata-driven canonical representation.

### canon_wide

Transforms canonical records into analysis-ready transaction structures.

### trans_analy

Final typed dataset for downstream analysis and reporting.

### trans_cleaned

Applies deterministic lexical cleaning to transaction descriptions while preserving the original bank-supplied text in `source_description`. This stage performs only non-semantic normalization, such as whitespace cleanup and removal of known boilerplate.

### trans_typed

Classifies transactions using metadata-driven transaction type rules. This stage adds transaction type metadata while preserving all columns produced by `trans_cleaned`.

### trans_normalized

Performs semantic normalization after transaction typing. This stage may simplify descriptions, remove transaction-type-specific boilerplate, or apply other semantic transformations while preserving the original and cleaned descriptions.

### trans_export

Provides a stable, user-facing dataset suitable for reporting, visualization, download, and downstream analytics. This view represents the recommended interface for most consumers of Finance Foundry
---

## Use Cases

### Personal Finance Aggregation

Combine exports from multiple institutions into a single transaction dataset.

Examples:

- Wells Fargo
- Chase
- American Express
- Credit card exports
- Brokerage exports

### Financial Analysis and Reporting

Prepare data for:

- spending analysis
- budgeting
- cash flow reporting
- dashboards
- business intelligence tools

### Schema-on-Read Data Engineering

Handle evolving file formats without rewriting ingestion logic.

Supports:

- multiple layouts per source
- layout evolution over time
- metadata-driven interpretation

### Fintech Prototyping

Build aggregation and analytics prototypes without requiring institution-specific APIs.

### Historical Financial Archives

Maintain long-term collections of financial exports while preserving the ability to interpret older formats correctly.

---

## Design Influences

Finance Foundry is heavily influenced by ideas from:

- Clinical programming
- Actuarial systems design

Both disciplines operate in environments where correctness, traceability, and reproducibility are critical.

Many design decisions in this project—including explicit transformation stages, row preservation checks, metadata-driven interpretation, and observability of failures—derive from those traditions.

Additional discussion can be found in:

- `docs/philosophy/inspiration.md`

---

## Current Implementation

The reference implementation is built using:

- AWS S3
- AWS Athena
- Metadata-driven SQL transformations

The architecture itself is platform-agnostic and can be adapted to other environments.

---

## Documentation

Additional documentation is available under:

- `docs/architecture/`
- `docs/governance/`
- `docs/philosophy/`

See `docs/README.md` for a complete documentation index.

---

## Future Directions

Potential future enhancements include:

- merchant identification
- transaction categorization
- enrichment layers
- cross-account reconciliation
- automated layout discovery
- layout workbench tooling

The current focus remains on reliable harmonization and traceable transformation of raw financial transaction data.
