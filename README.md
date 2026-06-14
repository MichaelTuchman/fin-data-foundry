# Finance Foundry

A framework for harmonizing financial data across multiple institutions and over time, with full row-level traceability and validation at every transformation stage.

## Why this exists

Financial data is difficult for two compounding reasons:

### 1. Multiple sources disagree

Different banks, brokers, and financial systems:

- Use different file formats
- Change layouts over time
- Encode account identity differently
- Represent the same concept in inconsistent ways

### 2. A single source is not stable over time

Even within one institution:

- File structures evolve without warning
- Historical “catch-up” files appear later
- Columns are added, removed, or reordered
- Semantics drift subtly across time periods

The result is a simple but painful question:

> **“Do these numbers actually represent the same thing across sources and time?”**

And an even worse one:

> **“Where did my rows go?”**

Finance Foundry exists to make those questions answerable.

---

## What this system guarantees

At its core, the system ensures:

> Every row from every source can be traced through every transformation stage, without silent loss or ambiguity.

---

## Core design principle

> Data must be consistent across sources, and consistent across time.

This system enforces that by making:

- Source differences explicit
- Temporal changes first-class
- Transformations fully traceable
- Row preservation measurable at every stage

---

## Pipeline overview

```
raw_csv
  → raw_boundary
  → file_context
  → layout_match
  → canon_long
  → canon_wide
  → trans_analy
```

Each stage progressively resolves ambiguity:

- **file_context**  
  Identifies source system, account, and file time coverage

- **layout_match**  
  Resolves which schema applies at that point in time

- **canon_long**  
  Normalizes heterogeneous inputs into a consistent event model

- **canon_wide**  
  Produces analysis-ready structure

- **trans_analy**  
  Final typed dataset for downstream analysis

---

## What makes this different

Most systems assume the hardest problem is transformation.

This system assumes the hardest problem is:

> **establishing that all data refers to the same conceptual reality across time and source systems**

Transformation is secondary. Reconciliation is primary.

---

## When to use this

Use Finance Foundry when:

- You are ingesting financial data from multiple institutions
- File formats evolve over time
- Historical data must remain comparable
- Silent data loss is unacceptable
- Auditability and traceability matter
