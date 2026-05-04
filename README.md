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


---

# 🗂️ S3 Setup (Getting Started)

This project assumes that users provide their own S3 bucket for storing raw financial data and metadata.

## 1. Create an S3 Bucket

Create a bucket of your choosing:

```
s3://your-finance-data/
```

---

## 2. Required Folder Structure

```
s3://your-finance-data/
    raw/
        wf/
        chase/
        amex/
    metadata/
```

### Explanation

| Folder | Purpose |
|------|--------|
| raw/ | Stores all uploaded bank CSV files |
| raw/<bank>/ | One subfolder per bank |
| metadata/ | Stores layout metadata files |

---

## 3. Uploading Bank Files

We recommend using short all-lowercase to describe your financial instutitions.  But the system does not mandate this.  For purpose of illustration, we'll assume two banks - Wells Fargo (wf) and Chase (chase).

```
s3://your-finance-data/raw/wf/
s3://your-finance-data/raw/chase/
```

---

## 4. Metadata File

```
s3://your-finance-data/metadata/layout_cols.csv
```

---

## 5. Conventions

- Folder name = `source_system` (again, wf or chase, one for each source system)
- Files should include YYYYMM for layout versioning, so if your bank changes layouts after a certain date, the system can cleanly infer the layout change.
- Do NOT flatten into a single folder.
  -- However, there is no requirement that you have to keep to a one-file per month or one-file per quarter format.
  -- Just that each file should have one layout.  If layout changes, start a new file, and update the metadata to reflect the change.

---

# 🏗️ Architecture

## Core Principles

### Separate ingestion from interpretation

Raw data arrival ≠ Data readiness

### Metadata controls behavior

No bank-specific SQL logic

### One table, one pipeline

```
finances.raw_csv
```

---

## Data Flow

```
Raw CSV
→ raw_csv (strings)
→ source_system from path
→ layout_cols
→ staging views
→ mart_bank_transactions
```

---

# 🔑 Key Concepts

## Source identification

```sql
regexp_extract("$path", 'raw/([^/]+)/', 1)
```

## Metadata-driven layout

- column_position → canonical_field
- effective dates control layout

## Metadata-gated output

Only sources with metadata appear

---

# ⚙️ Ingestion Rules

## CSV handling

All columns = STRING

## Header handling

Handled in views, not table definition

---

# 📦 Final Output

`finances.mart_bank_transactions`

Fields:

- transaction_dt
- posted_dt
- amount
- raw_description
- normalized_description
- account_name
- source_system
- layout_id

---

# 🚀 Operational Model

## Add data

Upload files only

## Activate bank

Add metadata rows

## Update layout

Insert new layout, close old one

---

# 🎯 Benefits

- Scalable
- Safe
- Maintainable
- Explainable

---

# 📌 Current Status

- Unified ingestion layer
- Metadata-driven layout
- Wells Fargo implemented
- Other banks pending

---

# 🔮 Next Steps

- Add more banks
- Add validation
- Add categorization
- Build analytics

---

# 🧾 Summary

Messy bank exports → standardized dataset via metadata
