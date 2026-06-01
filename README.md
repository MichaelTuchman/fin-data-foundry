# fin-data-foundry

Metadata-driven framework for **normalizing inconsistent bank CSV data into a unified transaction model**.

Most banks export transaction data differently—and often change formats over time.  
As a result, combining or analyzing data across accounts becomes manual, fragile, and time-consuming.

**fin-data-foundry** solves this by separating *data ingestion* from *data interpretation*.  
Raw CSV files are ingested as-is, and metadata defines how each format should be transformed into a standardized schema.

The name *foundry* is intentional:

> A foundry transforms raw, unrefined material into consistent, usable forms.

This system applies the same idea to financial data—casting heterogeneous inputs into a single, queryable transaction dataset.

It enables normalization of bank CSV data, standardization of financial transactions, and metadata-driven ingestion using SQL and AWS Athena.

This approach moves beyond traditional data pipelines. By using metadata to define structure, the system acts as an early form of **assisted data modeling**—helping transform inconsistent inputs into a consistent, queryable schema with minimal manual effort.

---

## ⚠️ Current Implementation

The reference implementation in this repository is developed and tested on AWS (S3 + Athena).

The overall approach is platform-agnostic and can be adapted to other environments (e.g., Azure, GCP, or local SQL engines), but those implementations are not yet provided.

---

# 🧩 Use Cases

This project is designed for anyone dealing with inconsistent financial data across multiple sources.  Even within the same bank, formats often change over time.

## 🏦 Personal Finance Aggregation

Combine transaction exports from multiple banks into a single dataset:

- Wells Fargo, Chase, Amex, etc.
- Different formats, column orders, and naming conventions
- Output: one consistent transaction table for analysis

---

## 📊 Financial Analysis & Reporting

Prepare clean, structured data for:

- spending analysis
- budgeting tools
- dashboards (Athena, BI tools, etc.)

Instead of manually cleaning each CSV, define the structure once in metadata.

---

## ⚙️ Data Engineering (Schema-on-Read)

Handle multiple CSV formats without rewriting pipelines:

- Different layouts over time
- Multiple schemas in a single directory
- No per-source ETL logic

This is especially useful for:
- AWS Athena / Presto / Trino workflows
- Data lakes with evolving schemas

---

## 🏗️ Fintech Prototyping

Build financial products without relying on APIs:

- Ingest exported bank data instead of API integrations
- Normalize into a common schema
- Prototype aggregation and analytics features quickly

---

## 🔁 Evolving Data Formats

Banks frequently change their export formats.

This system:
- supports multiple layouts per source
- uses effective dates to apply the correct schema
- avoids breaking existing pipelines

---
## 🔮 Future Directions

This framework focuses on standardizing raw financial transaction data.

A natural extension is higher-level interpretation, such as:

- merchant identification
- transaction categorization
- enrichment of normalized data

Early prototypes of these capabilities exist, but are not yet part of this repository.

# 📚 Documentation

Detailed setup, architecture, and usage instructions are available in the project Wiki (ready 5/12/26)

👉 [Project Wiki](../../wiki)

Hardcoded S3 bucket names currently exist.
This is known and accepted.

---

