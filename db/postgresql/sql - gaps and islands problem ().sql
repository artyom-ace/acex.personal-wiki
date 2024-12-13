-- Gaps and islands problem
-- Combining continuous intervals taking into account possible interval breaks.
-- Объединение непрерывных интервалов с учетом возможных разрывов.

------------------------------------------------------------------------------------------------------------------------

WITH problem AS (
    SELECT
        sn.data ->> '109-1' AS value,
        CASE WHEN sn.data ->> '109-1' = LAG(sn.data ->> '109-1') OVER (ORDER BY ap.created_at) THEN 0 ELSE 1 END AS same,
        sn.created_at AS created_at
    FROM ms_ap_snapshot_by_change sn
        JOIN ms_tko_accountingpoint ap ON sn.ap_id = ap.id
    WHERE ap.mp_id IN ('62Z24869929161--') AND sn.data ->> '109-1' IS NOT NULL
)
-- select * from problem;
, problem_2 AS (
     SELECT
        *,
        SUM(same) OVER ( ORDER BY created_at) AS rnk
     FROM problem
)
-- select * from problem_2;
select
    value,
    min(created_at) beginn,
    max(created_at) ends
from problem_2 group by value, rnk order by beginn;

------------------------------------------------------------------------------------------------------------------------

WITH
    ordered_data AS (
    SELECT ap_id, valid_from, valid_to, data, period_begin, period_end,
        LAG(period_end) OVER (PARTITION BY ap_id, valid_from, valid_to, data ORDER BY period_begin) AS prev_period_end
    FROM
        ms_ap_snapshot_by_validity__past
    WHERE
        ap_id = 876873
        AND data = '{"206-2": "ЮО", "206-3": "--------", "206-4": "юрособа"}'::jsonb
)
--  select * from ordered_data;
, grouped_data AS (
    SELECT
        ap_id, valid_from, valid_to, data, period_begin, period_end,
        SUM(CASE WHEN period_begin = prev_period_end THEN 0 ELSE 1 END) OVER (PARTITION BY ap_id, valid_from, valid_to, data ORDER BY period_begin) AS period_group
    FROM
        ordered_data
)
-- select * from grouped_data;
SELECT
    ap_id, valid_from, valid_to, MIN(period_begin) AS period_begin, MAX(period_end) AS period_end, data
FROM grouped_data GROUP BY ap_id, valid_from, valid_to, data, period_group ORDER BY period_begin;
