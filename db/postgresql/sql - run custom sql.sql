DO $$
    BEGIN
         raise info '%', format('insert into profiling_dko (log_id, pdate, data_type, inout_type, p_eic, p_eic_id, ph%s) values (%s, %L, %L, 0, %L, %s, %s)',
                          LPAD(myhour::text, 2, '0'),vlog_id, myday, vdata_type, eic, v_id, v_in);

         execute format('insert into profiling_dko (log_id, pdate, data_type, inout_type, p_eic, p_eic_id, ph%s) values (%s, %L, %L, 0, %L, %s, %s)',
                         LPAD(myhour::text, 2, '0'),vlog_id, myday, vdata_type, eic, v_id, v_in);
    end;
$$;
