
DO $$
    DECLARE
        vData jsonb := '{"key1": "value1", "key2": "value2", "key3": "value3"}'::jsonb;
        vKey text;
        vValue text;
    BEGIN
        FOR vKey, vValue IN
            SELECT * FROM jsonb_each_text(vData)
        LOOP
            RAISE NOTICE 'Key: %, Value: %', vKey, vValue;
        END LOOP;
    end;
$$;
