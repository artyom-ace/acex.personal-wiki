-- join ms_tko_accountingpoint with first snapshot and get birth_date

WITH first_snap AS (
    SELECT ap_id, data->>'101-1' as birth_date, ROW_NUMBER() OVER (PARTITION BY ap_id ORDER BY created_at) AS rn FROM ms_ap_snapshot_by_change
)
SELECT ap.*, sn.birth_date FROM ms_tko_accountingpoint ap JOIN first_snap sn ON ap.id = sn.ap_id WHERE sn.rn = 1;
