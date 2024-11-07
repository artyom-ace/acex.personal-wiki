-- convert any datetime value to date beginning in utc
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