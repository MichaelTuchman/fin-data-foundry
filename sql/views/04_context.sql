CREATE OR REPLACE VIEW finances.file_context AS
WITH parsed AS (
    SELECT
        source_file_path,
        regexp_extract(source_file_path, '[^/]+$') AS source_file_name,
        regexp_extract(source_file_path, 'raw/([^/]+)/', 1) AS source_system,
        regexp_extract(source_file_path, 'raw/[^/]+/([^/]+)/', 1) AS account_id,
        regexp_extract(source_file_path, '(\d{6})_(\d{6})', 1) AS range_start_yyyymm,
        regexp_extract(source_file_path, '(\d{6})_(\d{6})', 2) AS range_end_yyyymm,
        regexp_extract(source_file_path, '(\d{4})_Q([1-4])', 1) AS q_year,
        regexp_extract(source_file_path, '(\d{4})_Q([1-4])', 2) AS q_num,
        regexp_extract(source_file_path, '(\d{6})', 1) AS yyyymm,
        regexp_extract(source_file_path, '(\d{4})(?!\d)', 1) AS yyyy,
        derived_row_serial,
        col01,
        col02,
        col03,
        col04,
        col05,
        col06,
        col07,
        col08,
        col09,
        col10
    FROM finances.raw_serial
),
dated AS (
    SELECT
        source_file_path,
        source_file_name,
        source_system,
        account_id,
        CASE
            WHEN range_start_yyyymm <> '' THEN try_cast(date_parse(range_start_yyyymm, '%Y%m') AS date)
            WHEN q_year <> '' AND q_num = '1' THEN try_cast(q_year || '-01-01' AS date)
            WHEN q_year <> '' AND q_num = '2' THEN try_cast(q_year || '-04-01' AS date)
            WHEN q_year <> '' AND q_num = '3' THEN try_cast(q_year || '-07-01' AS date)
            WHEN q_year <> '' AND q_num = '4' THEN try_cast(q_year || '-10-01' AS date)
            WHEN yyyymm <> '' THEN try_cast(date_parse(yyyymm, '%Y%m') AS date)
            WHEN yyyy <> '' THEN try_cast(yyyy || '-01-01' AS date)
            ELSE NULL
        END AS file_start_dt,
        CASE
            WHEN range_end_yyyymm <> '' THEN date_add(
                'day',
                -1,
                date_add('month', 1, try_cast(date_parse(range_end_yyyymm, '%Y%m') AS date))
            )
            WHEN q_year <> '' AND q_num = '1' THEN try_cast(q_year || '-03-31' AS date)
            WHEN q_year <> '' AND q_num = '2' THEN try_cast(q_year || '-06-30' AS date)
            WHEN q_year <> '' AND q_num = '3' THEN try_cast(q_year || '-09-30' AS date)
            WHEN q_year <> '' AND q_num = '4' THEN try_cast(q_year || '-12-31' AS date)
            WHEN yyyymm <> '' THEN date_add(
                'day',
                -1,
                date_add('month', 1, try_cast(date_parse(yyyymm, '%Y%m') AS date))
            )
            WHEN yyyy <> '' THEN try_cast(yyyy || '-12-31' AS date)
            ELSE NULL
        END AS file_end_dt,
        derived_row_serial,
        col01,
        col02,
        col03,
        col04,
        col05,
        col06,
        col07,
        col08,
        col09,
        col10
    FROM parsed
)
SELECT
    source_file_path,
    source_file_name,
    source_system,
    account_id,
    file_start_dt,
    file_end_dt,
    derived_row_serial,
    col01,
    col02,
    col03,
    col04,
    col05,
    col06,
    col07,
    col08,
    col09,
    col10
FROM dated
