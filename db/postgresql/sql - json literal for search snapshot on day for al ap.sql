explain analyze
WITH ap_ids AS (
    SELECT
        id AS ap_id
    FROM artko.ms_tko_accountingpoint ap
    WHERE point_type_id = 2
    ORDER BY ap.id
    OFFSET 0 LIMIT 200_000
)

, snap_select AS (
    SELECT
        ap_ids.ap_id
-- snap.p104x4,
-- snap.p106x2
-- COUNT(1)
    FROM
        ap_ids
JOIN LATERAL (
    SELECT DISTINCT ON(sn.ap_id)
        sn.ap_id
--         data ->> '104-4' AS p104x4,
--         data ->> '106-2' AS p106x2
    FROM artko.ms_ap_snapshot_by_change sn
    WHERE sn.ap_id = ap_ids.ap_id AND created_at <= '2025-08-04'
    ORDER BY sn.ap_id, sn.created_at DESC
    ) snap ON TRUE
--     GROUP BY
--         snap.p104x4, snap.p106x2
)

SELECT * FROM snap_select;