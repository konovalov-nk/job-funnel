select
    cast(regexp_extract(filename, '(\d{4}-\d{2}-\d{2})', 1) as date) as activity_date,
    count(*) filter (where status = 'active') as discovered,
    count(*) filter (where status = 'closed') as closed,
    count(*) filter (where status = 'active')
      - count(*) filter (where status = 'closed') as net_active,
    count(distinct company_id) as companies_touched
from read_parquet(
    '/data/openjobdata/data/full/changes/*.parquet',
    filename = true,
    union_by_name = true
)
group by 1
order by 1
