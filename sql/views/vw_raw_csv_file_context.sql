create or replace view vw_raw_csv_file_content as
select
    regexp_extract("$path", '.*/([^/]+)/[^/]+$', 1) as account_id,
    regexp_extract("$path", '.*/([^/]+)/[^/]+/[^/]+$', 1) as source_system,
    "$path" as source_path,
    regexp_extract("$path", '.*/([^/]+)$', 1) as file_name,

    regexp_extract(regexp_extract("$path", '.*/([^/]+)$', 1), '([0-9]{6})', 1) as file_start_yyyymm,
    regexp_extract(regexp_extract("$path", '.*/([^/]+)$', 1), '([0-9]{6})', 1) as file_end_yyyymm,

    r.source_row_number,

    a.account_label,
    a.account_type,
    a.institution,

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

from raw_csv r
left join accounts a
  on regexp_extract("$path", '.*/([^/]+)/[^/]+$', 1) = a.account_id
 and regexp_extract("$path", '.*/([^/]+)/[^/]+/[^/]+$', 1) = a.source_system;

-- Fields:
-- source_system
-- account_id
-- source_path
-- file_name
-- file_start_yyyymm
-- file_end_yyyymm
-- source_row_number
-- account_label
-- account_type
-- institution
-- col01
-- col02
-- col03
-- col04
-- col05
-- col06
-- col07
-- col08
-- col09
-- col10

