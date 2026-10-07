CREATE OR REPLACE VIEW jobs AS
SELECT *
FROM read_parquet(
    '/data/openjobdata/data/full/part-*.parquet',
    union_by_name = true
);

CREATE OR REPLACE VIEW companies AS
SELECT *
FROM read_parquet('/data/openjobdata/data/companies/companies.parquet');

CREATE OR REPLACE VIEW job_changes AS
SELECT *, filename
FROM read_parquet(
    '/data/openjobdata/data/full/changes/*.parquet',
    union_by_name = true,
    filename = true
);
