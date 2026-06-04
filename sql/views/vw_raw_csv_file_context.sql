-- 1. vw_raw_csv_file_context

CREATE OR REPLACE VIEW vw_raw_csv_file_context AS
SELECT
    regexp_extract("$path", '.*/([^/]+)/([^/]+)/[^/]+$', 1) AS source_system,
    regexp_extract("$path", '.*/([^/]+)/([^/]+)/[^/]+$', 2) AS account_id,
    a.account_label,
    a.account_type,
    a.institution,
    "$path" AS source_path,
    regexp_extract("$path", '.*/([^/]+)$', 1) AS file_name,
    regexp_extract(regexp_extract("$path", '.*/([^/]+)$', 1), '([0-9]{6})', 1) AS file_start_yyyymm,
    regexp_extract(regexp_extract("$path", '.*/([^/]+)$', 1), '([0-9]{6})', 1) AS file_end_yyyymm,
    r.source_row_number,
    r.col01,
    r.col02,
    r.col03,
    r.col04,
    r.col05,
    r.col06,
    r.col07,
    r.col08,
    r.col09,
    r.col10
FROM raw_csv r
LEFT JOIN metadata_accounts a
  ON regexp_extract("$path", '.*/([^/]+)/([^/]+)/[^/]+$', 1) = a.source_system
 AND regexp_extract("$path", '.*/([^/]+)/([^/]+)/[^/]+$', 2) = a.account_id;
