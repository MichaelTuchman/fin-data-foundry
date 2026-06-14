create or replace view finances.file_context as
select
  source_file_path,
  regexp_extract(source_file_path, '[^/]+$') as source_file_name,
  regexp_extract(source_file_path, 'raw/([^/]+)/', 1) as source_system,
  regexp_extract(source_file_path, 'raw/[^/]+/([^/]+)/', 1) as account_id,
  try_cast(
    date_parse(
      regexp_extract(source_file_path, '(\\d{6})', 1),
      '%Y%m'
    ) as date
  ) as file_start_dt,
 date_add(
    'day',
    -1,
    date_add(
      'month',
      1,
      try_cast(
        date_parse(
          regexp_extract(source_file_path, '(\\d{6})', 1),
          '%Y%m'
        ) as date
      )
    )
  ) as file_end_dt,
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
from finances.raw_serial
