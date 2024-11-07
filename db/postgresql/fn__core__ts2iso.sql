create function fn__core__ts2iso(ts text) returns text
    language plpgsql
as
$$
    declare tz_dir text;
    declare tz_hour text;
    declare tz_minute text;
    declare normalized_ts timestamp;
    declare current_tz text;
    declare tmp_rec record;
    begin
        select current_setting('TIMEZONE') into current_tz;

        -- 01.02.2022 -> 2022-02-01
        -- 01-02-2022 -> 2022-02-01
        if regexp_match(ts, '^(\d{2})[\/.-](\d{2})[\/.-](\d{4})(.+)?$') is not null then
            ts = regexp_replace(ts, '^(\d{2})[\/.-](\d{2})[\/.-](\d{4})(.+)?$', '\2-\1-\3\4');

        -- 2022.01.02 -> 2022-01-02
        elseif regexp_match(ts, '^(\d{4})[\/.-](\d{2})[\/.-](\d{2})(.+)?$') is not null then
            ts = regexp_replace(ts, '^(\d{4})[\/.-](\d{2})[\/.-](\d{2})(.+)?$', '\1-\2-\3\4');
        end if;

        perform ts::timestamp;

        -- ^2022-03-10$ / ^10-03-2022$
        -- ^9999-12-31 02:00:00 / ^9999-12-31 02:00 / ^9999-12-31
        if regexp_match(ts, '[:\.]{1}\d+[+-](2[0-3]|[01][0-9])') is null then
            normalized_ts = ts::timestamp at time zone current_tz at time zone 'UTC';
            tz_dir = '+';
            tz_hour = '00';
            tz_minute = '00';
        end if;

        -- 9999-12-31 23:59:59+0200 / 9999-12-31 23:59:59+0000
        if regexp_match(ts, '[:\.]{1}\d+([+-])(2[0-3]|[01][0-9])([0-5][0-9])$') is not null then
            normalized_ts = ts::timestamp;
            select x[1] as x1, x[2] as x2, x[3] as x3 from (
                select regexp_match(ts, '[:\.]{1}\d+([+-])(2[0-3]|[01][0-9])([0-5][0-9])$') x
            ) y into tmp_rec;
            tz_dir = tmp_rec.x1;
            tz_hour = tmp_rec.x2;
            tz_minute = tmp_rec.x3;
        end if;

        -- 9999-12-31 23:59:59+02:00 / 9999-12-31 23:59:59+00:00
        if regexp_match(ts, '[:\.]{1}\d+([+-])(2[0-3]|[01][0-9]):([0-5][0-9])$') is not null then
            normalized_ts = ts::timestamp;
            select x[1] as x1, x[2] as x2, x[3] as x3 from (
                select regexp_match(ts, '[:\.]{1}\d+([+-])(2[0-3]|[01][0-9]):([0-5][0-9])$') x
            ) y into tmp_rec;
            tz_dir = tmp_rec.x1;
            tz_hour = tmp_rec.x2;
            tz_minute = tmp_rec.x3;
        end if;

        -- 9999-12-31 23:59:59+02 / 9999-12-31 23:59:59+00
        if regexp_match(ts, '[:\.]{1}\d+([+-])(2[0-3]|[01][0-9])$') is not null then
            normalized_ts = ts::timestamp;
            select x[1] as x1, x[2] as x2 from (
                select regexp_match(ts, '[:\.]{1}\d+([+-])(2[0-3]|[01][0-9])$') x
            ) y into tmp_rec;
            tz_dir = tmp_rec.x1;
            tz_hour = tmp_rec.x2;
            tz_minute = '00';
        end if;
        return to_char(normalized_ts, 'YYYY-MM-DD"T"HH24:MI:SS' || tz_dir || tz_hour || ':' || tz_minute);

    end;
$$;
