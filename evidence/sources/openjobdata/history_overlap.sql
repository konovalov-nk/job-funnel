with changes as (
    select
        id,
        status,
        cast(regexp_extract(filename, '(\d{4}-\d{2}-\d{2})', 1) as date) as activity_date
    from read_parquet(
        '/data/openjobdata/data/full/changes/*.parquet',
        filename = true,
        union_by_name = true
    )
), cutoff as (
    select max(activity_date) as latest_date from changes
), latest as (
    select id, status from changes, cutoff where activity_date = latest_date
), earlier as (
    select
        id,
        bool_or(status = 'active') as was_active,
        bool_or(status = 'closed') as was_closed
    from changes, cutoff
    where activity_date < latest_date
    group by id
)
select
    latest.status,
    count(*) as row_count,
    count(*) filter (where earlier.id is not null) as seen_earlier,
    count(*) filter (where earlier.was_active) as seen_earlier_active,
    count(*) filter (where earlier.was_closed) as seen_earlier_closed
from latest
left join earlier using (id)
group by latest.status
order by latest.status
