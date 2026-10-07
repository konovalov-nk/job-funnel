with changes as (
    select
        company_id,
        status,
        cast(regexp_extract(filename, '(\d{4}-\d{2}-\d{2})', 1) as date) as activity_date
    from read_parquet(
        '/data/openjobdata/data/full/changes/*.parquet',
        filename = true,
        union_by_name = true
    )
), latest as (
    select * from changes where activity_date = (select max(activity_date) from changes)
), companies as (
    select * from read_parquet('/data/openjobdata/data/companies/companies.parquet')
)
select
    coalesce(companies.name, cast(latest.company_id as varchar)) as company,
    count(*) filter (where latest.status = 'active') as discovered,
    count(*) filter (where latest.status = 'closed') as closed,
    count(*) filter (where latest.status = 'active')
      - count(*) filter (where latest.status = 'closed') as net_active
from latest
left join companies on companies.id = latest.company_id
group by 1
order by discovered + closed desc
