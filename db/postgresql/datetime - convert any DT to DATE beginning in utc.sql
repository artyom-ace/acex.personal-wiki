-- convert any datetime value to date beginning in utc

SELECT  date_trunc('day', '2024-02-29 22:10:00.000000 +0000', 'Europe/Kiev');

DO $$
    DECLARE vTime_org timestamptz;
    DECLARE vTime_mod timestamptz;
    declare normalized_ts timestamp;
    declare current_tz text;
    BEGIN
        RAISE INFO '[%] Start ...', to_char(now(), 'YYYY-MM-DD HH24:MI:ss');

        select current_setting('TIMEZONE') into current_tz;
        RAISE INFO 'current_tz: %', current_tz;
        current_tz = 'Europe/Kiev';
        RAISE INFO 'current_tz: %', current_tz;

        vTime_org = '2022-04-12 23:33:00.000000 +00:00'; -- now();
        RAISE INFO 'vTime_org: %', vTime_org;

        normalized_ts = vTime_org::timestamp at time zone 'UTC' at time zone current_tz;
        RAISE INFO 'normalized_ts: %', normalized_ts;

        vTime_mod = date_trunc('day', normalized_ts)::timestamp at time zone current_tz;
        RAISE INFO 'vTime_mod: %', vTime_mod;
    end;
$$;

------------------------------------------------------------------------------------------------------------------------

DO $$
    DECLARE vTime_org timestamptz;
    DECLARE vTime_mod timestamptz;
    DECLARE vTime_mod_txt text;
    BEGIN

        RAISE INFO '[%] Start ...', to_char(now(), 'YYYY-MM-DD HH24:MI:ss');
        vTime_org = '2022-04-12 11:33:00.000000 +00:00'; now();
        vTime_mod = date_trunc('day', vTime_org);
        vTime_mod_txt = fn__core__ts2iso((fn__core__ts2iso(vTime_mod::text)::timestamp at time zone 'Europe/Kiev')::text);
        RAISE INFO 'vTime_mod_txt: %', vTime_mod_txt;
    end;
$$;