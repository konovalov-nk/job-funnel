with changes as (
    select
        status,
        company_id,
        cast(regexp_extract(filename, '(\d{4}-\d{2}-\d{2})', 1) as date) as activity_date
    from read_parquet(
        '/data/openjobdata/data/full/changes/*.parquet',
        filename = true,
        union_by_name = true
    )
), latest as (
    select status, company_id, activity_date
    from changes
    where activity_date = (select max(activity_date) from changes)
), by_company as (
    select
        company_id,
        count(*) filter (where status = 'active') as discovered,
        count(*) filter (where status = 'closed') as closed
    from latest
    group by 1
), ranked as (
    select
        *,
        row_number() over (order by discovered desc) as discovery_rank,
        row_number() over (order by closed desc) as closure_rank
    from by_company
)
select
    (select max(activity_date) from latest) as activity_date,
    (select count(*) filter (where status = 'active') from latest) as discovered,
    (select count(*) filter (where status = 'closed') from latest) as closed,
    (select count(*) filter (where status = 'active') - count(*) filter (where status = 'closed') from latest) as net_active,
    count(*) as companies_touched,
    count(*) filter (where discovered > 0) as companies_discovering,
    count(*) filter (where closed > 0) as companies_closing,
    count(*) filter (where discovered > 0 and closed > 0) as companies_both,
    sum(discovered) filter (where discovery_rank <= 10) as top10_discovered,
    sum(discovered) filter (where discovery_rank <= 100) as top100_discovered,
    sum(closed) filter (where closure_rank <= 10) as top10_closed,
    sum(closed) filter (where closure_rank <= 100) as top100_closed,
    corr(discovered, closed) as company_flow_correlation
from ranked
