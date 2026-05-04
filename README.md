# fin-data-foundry
Metadata-driven pipeline for ingesting and normalizing multi-bank  financial CSV data into a unified transaction model. 


## Overview

**fin-data-foundry** is a metadata-driven framework for transforming raw financial data into a standardized, queryable transaction model.

The name *foundry* is intentional:

> A foundry takes raw, unrefined material and transforms it into consistent, usable forms.

This system applies the same idea to financial data:

- Raw bank CSV exports are treated as unrefined input
- Metadata defines how that data should be shaped
- The output is a uniform, structured transaction dataset

Rather than building separate pipelines for each bank or file format, the system uses metadata to “cast” heterogeneous inputs into a single, consistent schema.

This approach enables:

- ingestion of new data without code changes  
- support for multiple banks and evolving formats  
- a clean separation between raw data and its interpretation  

In short, this repository is not just an ingestion pipeline—it is a **data foundry** for financial transactions.

# 🧩 Use Cases

This project is designed for anyone dealing with inconsistent financial data across multiple sources.  Moreover, we often have to deal with inconsistent data from the *same* source!

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
