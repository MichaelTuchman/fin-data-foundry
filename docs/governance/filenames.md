| Order | SQL File        | View Name     | Purpose |
|---------|----------------|---------------|----------|
| 01 | raw.sql       | raw_csv       | Physical Athena external table over uploaded CSV files |
| 02 | boundary.sql  | raw_bound     | Convert Athena metadata (`$path`) into ordinary columns |
| 03 | reshape.sql   | raw_reshape   | Generate temporary row numbers for long/wide reshaping |
| 04 | context.sql   | file_context  | Parse file path, account ID, source system, and file dates |
| 05 | layout.sql    | layout_match  | Resolve the applicable layout for each file |
| 06 | long.sql      | canon_long    | Convert rows to canonical long format and validate with regex rules |
| 07 | wide.sql      | canon_wide    | Pivot canonical long data back to transaction format |
| 08 | analyze.sql   | trans_analy   | Final analysis-ready dataset with typed fields |

## Dependency Graph

```text
raw_csv
│
▼
raw_bound
│
▼
raw_reshape
│
▼
file_context
│
▼
layout_match
│
▼
canon_long
│
▼
canon_wide
│
▼
trans_analy
```

## Naming Principles

- SQL files are numbered according to execution order.
- SQL filenames describe the responsibility of the layer.
- View names are kept between 8 and 12 characters where practical.
- Each layer owns exactly one responsibility.
- Downstream layers should not reimplement logic from upstream layers.
