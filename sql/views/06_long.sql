create or replace view finances.canon_long as
with raw_long as (
    select
        lm.source_file_path,
        lm.source_file_name,
        lm.source_system,
        lm.account_id,
        lm.file_start_dt,
        lm.file_end_dt,
        lm.layout_id,
        lm.derived_row_serial,
        u.column_position,
        u.raw_value
    from finances.layout_match lm
    cross join unnest(array[
        row(1, lm.col01),
        row(2, lm.col02),
        row(3, lm.col03),
        row(4, lm.col04),
        row(5, lm.col05),
        row(6, lm.col06),
        row(7, lm.col07),
        row(8, lm.col08),
        row(9, lm.col09),
        row(10, lm.col10)
    ]) as u(column_position, raw_value)
),
joined as (
    select
        r.source_file_path,
        r.source_file_name,
        r.source_system,
        r.account_id,
        r.file_start_dt,
        r.file_end_dt,
        r.layout_id,
        r.derived_row_serial,
        r.column_position,
        c.canonical_field,
        c.validation_type,
        c.validation_rule,
        c.required,
        r.raw_value
    from raw_long r
    join finances.metadata_layout_cols c
      on r.source_system = c.source_system
     and r.account_id = c.account_id
     and r.layout_id = c.layout_id
     and r.column_position = c.column_position
),
normalized as (
    select
        source_file_path,
        source_file_name,
        source_system,
        account_id,
        file_start_dt,
        file_end_dt,
        layout_id,
        derived_row_serial,
        column_position,
        canonical_field,
        validation_type,
        validation_rule,
        required,
        raw_value,
        case
            when raw_value is null or trim(raw_value) = '' then null
            when regexp_like(trim(raw_value), '^[(].*[)]$')
                then '-' || regexp_replace(
                    regexp_replace(trim(raw_value), '[^0-9.,-]', ''),
                    ',',
                    ''
                )
            else regexp_replace(
                regexp_replace(trim(raw_value), '[^0-9.,-]', ''),
                ',',
                ''
            )
        end as normalized_money_value
    from joined
)
select
    source_file_path,
    source_file_name,
    source_system,
    account_id,
    file_start_dt,
    file_end_dt,
    layout_id,
    derived_row_serial,
    column_position,
    canonical_field,
    validation_type,
    validation_rule,
    required,
    raw_value,
    case
        when raw_value is null or trim(raw_value) = '' then
            not coalesce(required, false)

        when lower(validation_type) = 'text' then
            true

        when lower(validation_type) = 'regex' then
            regexp_like(trim(raw_value), validation_rule)

        when lower(validation_type) = 'money' then
            try_cast(normalized_money_value as decimal(18,2)) is not null

        when lower(validation_type) = 'date_format'
             and lower(validation_rule) = 'iso_8601' then
            try_cast(trim(raw_value) as date) is not null

        when lower(validation_type) = 'date_format'
             and lower(validation_rule) = 'mdy_slash' then
            try(date_parse(trim(raw_value), '%m/%d/%Y')) is not null

        when lower(validation_type) = 'date_format' then
            try(date_parse(trim(raw_value), validation_rule)) is not null

        else
            false
    end as validation_passed
from normalized;
