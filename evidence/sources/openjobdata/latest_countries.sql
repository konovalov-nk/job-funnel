with changes as (
    select
        status,
        country,
        cast(regexp_extract(filename, '(\d{4}-\d{2}-\d{2})', 1) as date) as activity_date
    from read_parquet(
        '/data/openjobdata/data/full/changes/*.parquet',
        filename = true,
        union_by_name = true
    )
), latest as (
    select status, country, activity_date
    from changes
    where activity_date = (select max(activity_date) from changes)
)
select
    coalesce(nullif(country, ''), 'Unknown') as country,
    count(*) filter (where status = 'active') as discovered,
    count(*) filter (where status = 'closed') as closed
from latest
group by 1
order by discovered + closed desc
limit 25
