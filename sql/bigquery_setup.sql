-- BigQuery objects behind the Astrato dashboard
-- Project: engine-health-astrato-project   Dataset: engine_health (EU)
--
-- Tables (loaded from the notebook's CSV exports):
--   engine_history  - every cycle for the 100 training engines (20,631 rows)
--   fleet_snapshot  - latest reading for the 100 test engines, with true RUL and status (100 rows)

-- Engines that need attention, ranked by cycles left (33 rows)
CREATE OR REPLACE VIEW `engine_health.maintenance_queue` AS
SELECT
  RANK() OVER (ORDER BY RUL) AS priority,
  unit                       AS engine_id,
  cycle                      AS cycles_flown,
  RUL                        AS cycles_left,
  status
FROM `engine_health.fleet_snapshot`
WHERE status != 'Healthy';

-- Fleet grouped into 20-cycle bands of remaining life
CREATE OR REPLACE VIEW `engine_health.cycles_left_bands` AS
SELECT
  CAST(FLOOR(RUL / 20) * 20 AS INT64)                         AS band_start,
  FORMAT('%d-%d', CAST(FLOOR(RUL / 20) * 20 AS INT64),
                  CAST(FLOOR(RUL / 20) * 20 AS INT64) + 19)   AS cycles_left_band,
  COUNT(*)                                                    AS engines,
  COUNTIF(status = 'Critical')                                AS critical,
  COUNTIF(status = 'Watch')                                   AS watch,
  COUNTIF(status = 'Healthy')                                 AS healthy
FROM `engine_health.fleet_snapshot`
GROUP BY 1, 2;
