-- 7-day SILVER snapshot (idempotent)
DROP TABLE IF EXISTS iceberg.silver.test_events_clean_7d;

CREATE TABLE iceberg.silver.test_events_clean_7d
WITH (partitioning = ARRAY['event_date', 'station'])
AS
SELECT
  CAST(date(event_ts) AS date) AS event_date,
  site,
  line,
  station,
  serial,
  part_number,
  test_name,
  (upper(result) = 'PASS') AS pass,
  measurement,
  units
FROM iceberg.raw.test_events
WHERE date(event_ts) >= current_date - INTERVAL '7' DAY;

-- GOLD refresh from snapshot (incremental, safe to rerun)
MERGE INTO iceberg.gold.daily_yield t
USING (
  SELECT
    event_date,
    site,
    line,
    station,
    part_number,
    COUNT(*) AS total_tests,
    SUM(CASE WHEN pass THEN 1 ELSE 0 END) AS pass_tests,
    CAST(SUM(CASE WHEN pass THEN 1 ELSE 0 END) * 1.0 / COUNT(*) AS double) AS yield
  FROM iceberg.silver.test_events_clean_7d
  GROUP BY 1,2,3,4,5
) s
ON (
  t.event_date = s.event_date
  AND t.site = s.site
  AND t.line = s.line
  AND t.station = s.station
  AND t.part_number = s.part_number
)
WHEN MATCHED THEN UPDATE SET
  total_tests = s.total_tests,
  pass_tests  = s.pass_tests,
  yield       = s.yield
WHEN NOT MATCHED THEN INSERT (
  event_date, site, line, station, part_number, total_tests, pass_tests, yield
) VALUES (
  s.event_date, s.site, s.line, s.station, s.part_number,
  s.total_tests, s.pass_tests, s.yield
);
