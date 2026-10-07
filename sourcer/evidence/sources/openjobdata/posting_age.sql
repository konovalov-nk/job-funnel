with changes as (
    select
        status,
        posted_at,
        cast(regexp_extract(filename, '(\d{4}-\d{2}-\d{2})', 1) as date) as activity_date
    from read_parquet(
        '/data/openjobdata/data/full/changes/*.parquet',
        filename = true,
        union_by_name = true
    )
), latest as (
    select status, posted_at, activity_date
    from changes
    where activity_date = (select max(activity_date) from changes)
), aged as (
    select
        case
            when posted_at is null then 'Unknown'
            when date_diff('day', cast(posted_at as date), activity_date) <= 1 then '0-1 days'
            when date_diff('day', cast(posted_at as date), activity_date) <= 7 then '2-7 days'
            when date_diff('day', cast(posted_at as date), activity_date) <= 30 then '8-30 days'
            when date_diff('day', cast(posted_at as date), activity_date) <= 365 then '31-365 days'
            else 'Over 1 year'
        end as age_bucket,
        case
            when posted_at is null then 6
            when date_diff('day', cast(posted_at as date), activity_date) <= 1 then 1
            when date_diff('day', cast(posted_at as date), activity_date) <= 7 then 2
            when date_diff('day', cast(posted_at as date), activity_date) <= 30 then 3
            when date_diff('day', cast(posted_at as date), activity_date) <= 365 then 4
            else 5
        end as bucket_order
    from latest
    where status = 'active'
)
select age_bucket, count(*) as jobs
from aged
group by age_bucket, bucket_order
order by bucket_order
