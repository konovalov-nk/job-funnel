# Shore Template Reference

This Rails app was bootstrapped from the [Shore template](https://github.com/yatish27/shore).

- **URL:** https://github.com/yatish27/shore
- **Reference SHA:** `0211486b9b350cca0a25ce608601e960d61f985e`
- **License:** MIT

## Deviations

- Ruby version: declared as `4.0.1` in the spec/ruby-version; installed `4.0.5` (latest patch available via rbenv)
- Database name: `job_tracker_*` instead of `shore_*`
- `.bundle/config` removed (BUNDLE_WITH deploy not needed for development)

## Stack

| Component       | Version         |
|----------------|-----------------|
| Ruby           | 4.0.5           |
| Rails          | 8.1.2           |
| PostgreSQL     | 18              |
| React          | 19              |
| Inertia.js     | 3               |
| Vite           | 7               |
| Bun            | 1.3             |
| Solid Queue    | 1.3             |
| Solid Cache    | bundled with Rails |
| Solid Cable    | bundled with Rails |
| Tailwind CSS   | 4               |
