CREATE OR REPLACE VIEW file_context AS
SELECT
    source_file_path,
    regexp_extract(source_file_path, '([^/]+)$', 1) AS source_file_name,
    regexp_extract(source_file_path, 'raw/([^/]+)/([^/]+)/', 1) AS source_system,
    regexp_extract(source_file_path, 'raw/([^/]+)/([^/]+)/', 2) AS account_id,
    CAST(date_parse(regexp_extract(source_file_path, '([0-9]{6})', 1), '%Y%m') AS date) AS file_start_dt,
    date_add(
        'day',
        -1,
        date_add(
            'month',
            1,
            CAST(date_parse(regexp_extract(source_file_path, '([0-9]{6})', 1), '%Y%m') AS date)
        )
    ) AS file_end_dt,
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
FROM raw_serial
