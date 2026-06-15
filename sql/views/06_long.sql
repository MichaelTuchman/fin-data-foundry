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
        cast(u.column_pair[1] as integer) as column_position,
        u.column_pair[2] as raw_value
    from finances.layout_match lm
    cross join unnest(array[
        array['1', lm.col01],
        array['2', lm.col02],
        array['3', lm.col03],
        array['4', lm.col04],
        array['5', lm.col05],
        array['6', lm.col06],
        array['7', lm.col07],
        array['8', lm.col08],
        array['9', lm.col09],
        array['10', lm.col10]
    ]) as u(column_pair)
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
        lower(trim(c.validation_type)) as validation_type,
        lower(trim(c.validation_rule)) as validation_rule,
        lower(trim(c.required)) as required,
        r.raw_value
    from raw_long r
    join finances.metadata_layout_cols c
      on r.source_system = c.source_system
     and r.account_id = c.account_id
     and r.layout_id = c.layout_id
     and r.column_position = try_cast(c.column_position as integer)
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
            when regexp_like(trim(raw_value), '^[(].*[)]$') then
                '-' || regexp_replace(
                    regexp_replace(trim(raw_value), '[^0-9.,-]', ''),
                    ',',
                    ''
                )
            else
                regexp_replace(
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
            not (required = 'true')

        when validation_type = 'text' then
            true

        when validation_type = 'regex' then
            regexp_like(trim(raw_value), validation_rule)

        when validation_type = 'money' then
            try_cast(normalized_money_value as decimal(18,2)) is not null

        when validation_type = 'date_format'
             and validation_rule = 'iso_8601' then
            try_cast(trim(raw_value) as date) is not null

        when validation_type = 'date_format'
             and validation_rule = 'mdy_slash' then
            try(date_parse(trim(raw_value), '%m/%d/%Y')) is not null

        when validation_type = 'date_format' then
            try(date_parse(trim(raw_value), validation_rule)) is not null

        else
            false
    end as validation_passed
from normalized;
