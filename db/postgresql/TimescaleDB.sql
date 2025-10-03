-- ## Create hypertable

CREATE OR REPLACE FUNCTION kiev_time_partitioning(timestamptz)
RETURNS timestamptz AS $$
BEGIN
    -- Преобразуем время в киевскую зону и обрезаем до начала дня
    RETURN date_trunc('day', $1 AT TIME ZONE 'Europe/Kiev') AT TIME ZONE 'Europe/Kiev';
END;
$$ LANGUAGE plpgsql IMMUTABLE;


CREATE TABLE bench.z_profiling (
    accounting_id int4 NOT NULL,
    z_id int4 NOT NULL,
    z_time timestamptz NOT NULL,
    z_quantity float8 NOT NULL,
    PRIMARY KEY (accounting_id, z_id, z_time)
);

-- Создание гипертаблицы с учетом смещения UTC+2
SELECT create_hypertable(
    'bench.z_profiling',
    'z_time',
    chunk_time_interval => INTERVAL '1 day',
    create_default_indexes => FALSE,
    partitioning_func => 'kiev_time_partitioning'
);

--Создание индексов
CREATE INDEX ON bench.z_profiling (z_time DESC);
CREATE INDEX ON bench.z_profiling (accounting_id, z_time DESC);





--
ALTER TABLE bench.z_profiling SET (
    timescaledb.compress,
    timescaledb.compress_segmentby = 'accounting_id',
    timescaledb.compress_orderby = 'z_time DESC, z_id'
);

-- Ручная компрессия конкретного чанка
SELECT compress_chunk(chunk_name) FROM timescaledb_information.chunks WHERE hypertable_name = 'z_profiling' AND range_end < NOW() - INTERVAL '7 days';



-- ## Size
SELECT
    hypertable_schema,
    hypertable_name,
    pg_size_pretty(hypertable_size(hypertable_schema||'.'||hypertable_name)) as hypertable_size_pretty,
    ROUND(hypertable_size(hypertable_schema||'.'||hypertable_name) / (1024.0^3), 3) as hypertable_size_gb,
    num_chunks,
    compression_enabled
FROM timescaledb_information.hypertables
WHERE hypertable_name LIKE '%z_file_data%'
OR hypertable_name LIKE '%file_data%';


-- ## Compression
-- + compression up to 90-95%
-- + low I/O operation
-- + fast SELECT
--
-- - compressed chunks read-only
-- - UPDATE/DELETE only on decompressed chunks
-- - high latency on INSERT (before INSERT compressed chunk will be decompressed)
-- - higher CPU load

-- ## Compression policy
-- Compress data automatically after a certain time period.
SELECT add_compression_policy('bench.z_profiling', INTERVAL '30 days');

-- ## Compression policy status
SELECT chunk_name, is_compressed FROM timescaledb_information.chunks WHERE hypertable_name = 'z_profiling';

-- ## Manual compression of chunks
SELECT compress_chunk(chunk_name) FROM timescaledb_information.chunks WHERE hypertable_name = 'z_profiling' AND NOT is_compressed;
