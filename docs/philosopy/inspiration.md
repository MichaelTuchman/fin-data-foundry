# Inspiration

Finance Foundry is inspired by practices and principles from clinical programming and actuarial system design.

These domains operate in environments where correctness, traceability, and auditability are non-negotiable. Small inconsistencies are not treated as noise — they are treated as system failures that must be explainable.

This project adapts those ideas to financial data integration across multiple institutions and over time.

---

## Clinical programming influence

Clinical data systems (e.g., SDTM / ADaM-style pipelines) emphasize:

### Traceability of derivations

Every derived value must be traceable back to its origin:

- Source datasets
- Transformation logic
- Intermediate derivations

In Finance Foundry, this is reflected in:

- Explicit intermediate transformation stages
- Deterministic pipeline structure
- Avoidance of opaque or hidden transformations

---

### Controlled evolution of data

Clinical systems assume data will evolve over time:

- Case report forms change
- Variables are added or deprecated
- Historical data must remain interpretable

Finance Foundry mirrors this through:

- Layout versioning over time
- Metadata-driven schema resolution
- Explicit handling of file-level temporal coverage

---

### Reproducibility requirement

Clinical analyses must be:

- Deterministic
- Reproducible
- Independent of execution context

This is reflected in:

- Fixed transformation stages
- Explicit parsing rules
- Stable row identity across the pipeline

---

## Actuarial influence

Actuarial systems are built on the principle of:

> Conserving meaning and quantity through transformation.

---

### Row conservation

At every stage of the pipeline:

```
row_count(input) = row_count(output)
```

Any deviation is treated as a system defect, not acceptable variance.

---

### Explicit assumptions

Actuarial models require assumptions to be:

- Explicit
- Testable
- Revisitable

In Finance Foundry this appears as:

- Layout validity windows
- File coverage derivation rules
- Metadata-driven interpretation of structure

---

### Sensitivity to silent error

Actuarial systems are designed to detect:

- small inconsistencies that accumulate over time
- hidden drift in assumptions
- unexplainable differences in outputs

Finance Foundry applies this directly by ensuring:

> No transformation is allowed to silently drop, duplicate, or reinterpret rows.

---

## Shared principles

Both domains converge on a small set of core requirements:

- Explainability is more important than convenience
- Failure must be visible and localizable
- Systems must remain stable under change
- Transformations must be traceable and inspectable

---

## Summary

Finance Foundry applies these principles to financial data by enforcing:

- explicit structure over implicit assumptions
- traceability over convenience
- invariants over best-effort transformation

The goal is simple:

> If a number changes, we should always be able to explain exactly why.
