CREATE OR REPLACE VIEW vw_raw_csv_file_context AS
WITH base AS (
    SELECT
        regexp_extract("$path", '/raw/([^/]+)/', 1) AS source_system,
        regexp_extract("$path", '/raw/[^/]+/([^/]+)/', 1) AS account_id,
        "$path" AS source_path,
        regexp_extract("$path", '[^/]+$', 0) AS file_name,

        col01, col02, col03, col04, col05,
        col06, col07, col08, col09, col10
    FROM raw_csv
),

parsed AS (
    SELECT
        *,
        regexp_extract_all(file_name, '(20[0-9]{2})[_-]?([0-1][0-9])') AS month_tokens,
        regexp_extract(file_name, '(20[0-9]{2})[_-]?[Qq]([1-4])', 1) AS quarter_year,
        regexp_extract(file_name, '(20[0-9]{2})[_-]?[Qq]([1-4])', 2) AS quarter_num,
        regexp_extract(file_name, '(20[0-9]{2})', 1) AS year_token
    FROM base
)

SELECT
    source_system,
    account_id,
    source_path,
    file_name,

    CASE
        WHEN cardinality(month_tokens) >= 1
            THEN regexp_replace(month_tokens[1], '[_-]', '')
        WHEN quarter_year <> ''
            THEN quarter_year ||
                 CASE quarter_num
                     WHEN '1' THEN '01'
                     WHEN '2' THEN '04'
                     WHEN '3' THEN '07'
                     WHEN '4' THEN '10'
                 END
        WHEN year_token <> ''
            THEN year_token || '01'
    END AS file_start_yyyymm,

    CASE
        WHEN cardinality(month_tokens) >= 2
            THEN regexp_replace(month_tokens[2], '[_-]', '')
        WHEN cardinality(month_tokens) = 1
            THEN regexp_replace(month_tokens[1], '[_-]', '')
        WHEN quarter_year <> ''
            THEN quarter_year ||
                 CASE quarter_num
                     WHEN '1' THEN '03'
                     WHEN '2' THEN '06'
                     WHEN '3' THEN '09'
                     WHEN '4' THEN '12'
                 END
        WHEN year_token <> ''
            THEN year_token || '12'
    END AS file_end_yyyymm,

    col01, col02, col03, col04, col05,
    col06, col07, col08, col09, col10

FROM parsed;
