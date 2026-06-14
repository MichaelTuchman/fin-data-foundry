create or replace view finances.layout_match as
select
  fc.source_file_path,
  fc.source_file_name,
  fc.source_system,
  fc.account_id,
  fc.file_start_dt,
  fc.file_end_dt,
  mlc.layout_id,
  fc.derived_row_serial,
  fc.col01,
  fc.col02,
  fc.col03,
  fc.col04,
  fc.col05,
  fc.col06,
  fc.col07,
  fc.col08,
  fc.col09,
  fc.col10
from finances.file_context fc
inner join finances.metadata_layout_controls mlc
  on fc.source_system = mlc.source_system
 and fc.account_id = mlc.account_id
 and fc.file_start_dt >= try_cast(mlc.layout_valid_from as date)
 and fc.file_end_dt <= coalesce(
      try_cast(nullif(mlc.layout_valid_to, '') as date),
      current_date
    )
