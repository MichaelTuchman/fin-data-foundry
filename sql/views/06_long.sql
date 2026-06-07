CREATE OR REPLACE VIEW canon_long AS
SELECT
    l.source_file_path,
    l.source_file_name,
    l.source_system,
    l.account_id,
    l.file_start_dt,
    l.file_end_dt,
    l.layout_id,
    l.raw_row_serial,
    u.raw_col.column_position,
    c.canonical_field,
    u.raw_col.raw_value,
    c.expected_pattern,
    c.required,
    regexp_like(u.raw_col.raw_value, c.expected_pattern) AS pattern_passed
FROM layout_match l
CROSS JOIN UNNEST(
    ARRAY[
        CAST(ROW(1, l.col01) AS ROW(column_position integer, raw_value varchar)),
        CAST(ROW(2, l.col02) AS ROW(column_position integer, raw_value varchar)),
        CAST(ROW(3, l.col03) AS ROW(column_position integer, raw_value varchar)),
        CAST(ROW(4, l.col04) AS ROW(column_position integer, raw_value varchar)),
        CAST(ROW(5, l.col05) AS ROW(column_position integer, raw_value varchar)),
        CAST(ROW(6, l.col06) AS ROW(column_position integer, raw_value varchar)),
        CAST(ROW(7, l.col07) AS ROW(column_position integer, raw_value varchar)),
        CAST(ROW(8, l.col08) AS ROW(column_position integer, raw_value varchar)),
        CAST(ROW(9, l.col09) AS ROW(column_position integer, raw_value varchar)),
        CAST(ROW(10, l.col10) AS ROW(column_position integer, raw_value varchar))
    ]
) AS u(raw_col)
INNER JOIN metadata_layout_cols c
    ON l.source_system = c.source_system
   AND l.layout_id = c.layout_id
   AND u.raw_col.column_position = CAST(c.column_position AS integer)
