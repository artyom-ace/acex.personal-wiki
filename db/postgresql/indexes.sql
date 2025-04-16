-- for JSONB
CREATE INDEX table__data ON _table_ USING GIN (data jsonb_path_ops);
-- GIN (data jsonb_path_ops) — more effective and compact index for @>
-- GIN (data) - more universal (->, ->>, ?), more slower for @>


-- for TSTZRANGE (can use GIST index or SP-GiST index (more effective for ranges))
-- https://www.postgresql.org/docs/current/spgist.html
CREATE INDEX table__period_range ON _table_ USING GIST (tstzrange(period_begin, period_end, '[]'));
CREATE INDEX table__period_range ON _table_ USING GIST (tstzrange(period_begin, period_end, '[)'));