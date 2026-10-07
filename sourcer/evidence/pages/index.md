---
title: OpenJobData Pulse
---

```sql summary
select * from openjobdata.latest_summary
```

```sql activity
select * from openjobdata.daily_activity
```

```sql top_companies
select * from openjobdata.latest_companies
order by discovered + closed desc
limit 30
```

```sql concentration
select
    'Top 10' as cohort,
    top10_discovered / discovered as discovery_share,
    top10_closed / closed as closure_share
from openjobdata.latest_summary
union all
select
    'Top 100',
    top100_discovered / discovered,
    top100_closed / closed
from openjobdata.latest_summary
```

```sql age
select * from openjobdata.posting_age
```

```sql countries
select * from openjobdata.latest_countries
```

```sql overlap
select * from openjobdata.history_overlap
```

# Dataset pulse

Последний опубликованный daily snapshot: **<Value data={summary} column=activity_date/>**.
Здесь `discovered` означает новый для OpenJobData `id`, а не гарантированно новую
публикацию работодателя. `closed` означает, что crawler обнаружил вакансию
закрытой; `close_time` является временем обнаружения.

<Grid cols=4>
    <BigValue data={summary} value=discovered title="Discovered IDs"/>
    <BigValue data={summary} value=closed title="Detected closures"/>
    <BigValue data={summary} value=net_active title="Net active"/>
    <BigValue data={summary} value=companies_touched title="Companies touched"/>
</Grid>

<LineChart
    data={activity}
    x=activity_date
    y={['discovered', 'closed']}
    yAxisTitle="Jobs"
    title="Daily crawler churn"
/>

## Какие сценарии подтверждаются

<Grid cols=3>
    <BigValue data={summary} value=companies_both title="Companies in both flows"/>
    <BigValue data={summary} value=company_flow_correlation title="Open/close correlation" fmt="0.00"/>
    <BigValue data={overlap.filter(x => x.status === 'active')} value=seen_earlier title="Active IDs seen earlier"/>
</Grid>

<Alert status="info">
Это глобальный распределённый churn, а не активность нескольких гигантов.
При этом значительная часть компаний одновременно получает новые ID и закрытия,
что похоже на очередной проход crawler по ATS-каталогам.
</Alert>

<BarChart
    data={concentration}
    x=cohort
    y={['discovery_share', 'closure_share']}
    yFmt=pct1
    title="Concentration of daily volume"
/>

## Компании

<ScatterPlot
    data={top_companies}
    x=discovered
    y=closed
    series=company
    xAxisTitle="Discovered IDs"
    yAxisTitle="Closures"
    title="Largest company flows"
/>

<DataTable data={top_companies} rows=20 search=true>
    <Column id=company/>
    <Column id=discovered/>
    <Column id=closed/>
    <Column id=net_active/>
</DataTable>

## Насколько новые вакансии действительно новые

<BarChart
    data={age}
    x=age_bucket
    y=jobs
    title="Age of discovered IDs by posted_at"
/>

Старые и неизвестные `posted_at` показывают ключевое ограничение: daily delta
фиксирует момент обнаружения записи OpenJobData, а не обязательно момент создания
вакансии работодателем.

## География последнего прохода

<DataTable data={countries} rows=25 search=true>
    <Column id=country/>
    <Column id=discovered/>
    <Column id=closed/>
</DataTable>
