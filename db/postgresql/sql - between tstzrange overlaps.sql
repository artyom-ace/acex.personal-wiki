-- OVELAPS--------------------------------------------------------------------------------------------------------------
-- renge is half-open interval START <= TIME < END

-- USES (start1, end1   ) OVERLAPS (start2, end2   )
--      (start1, length1) OVERLAPS (start2, length2)

-- special examples
SELECT (DATE '2001-02-19', INTERVAL '100 days') OVERLAPS (DATE '2001-05-30', DATE '2002-10-30'); -- Result: false (2001-02-19 + 100 days = 2001-05-30)
SELECT (DATE '2001-10-29', DATE '2001-10-30')   OVERLAPS (DATE '2001-10-30', DATE '2001-10-31'); -- Result: false
SELECT (DATE '2001-10-30', DATE '2001-10-30')   OVERLAPS (DATE '2001-10-30', DATE '2001-10-31'); -- Result: true

-- equal
SELECT tstzrange(DATE '2001-10-29', DATE '2001-10-30', '[)') && tstzrange(DATE '2001-10-30', DATE '2001-10-31', '[)');


-- TSTZRANGE -----------------------------------------------------------------------------------------------------------
SELECT tstzrange(DATE '2001-10-01', DATE '2001-11-01', '[)') @> '2001-11-01'::TIMESTAMPTZ;
-- equal
SELECT '2001-10-01'::DATE <= '2001-11-01'::::TIMESTAMPTZ  AND  '2001-11-01'::DATE > '2001-11-01'::::TIMESTAMPTZ;

-- range bounds
-- (lower, upper) - exclusive, exclusive
-- (lower, upper] - exclusive, inclusive
-- [lower, upper) - inclusive, exclusive
-- [lower, upper] - inclusive, inclusive
-- SELECT int8range(1, 14, '(]');    |     SELECT '[4,4)'::int4range;

-- operators
-- @> - Диапазон содержит значение или другой диапазон
-- <@ - Значение входит в диапазон
-- && - Диапазоны пересекаются
--  = - Диапазоны равны
-- <> - Диапазоны не равны
-- << - Левый диапазон полностью перед правым
-- >> - Левый диапазон полностью после правого
-- &< - Левый диапазон пересекается с правым, но начинается раньше
-- &> - Левый диапазон пересекается с правым, но начинается позже

--  ~= - Диапазоны пересекаются или равны
-- -|- - Диапазоны не пересекаются
-- <<| - Левый диапазон полностью перед правым или пересекается с ним
-- |>> - Левый диапазон полностью после правого или пересекается с ним
-- &<| - Левый диапазон пересекается с правым, но начинается раньше или равен ему
-- |&> - Левый диапазон пересекается с правым, но начинается позже или равен ему


-- TSTZRANGE can use GIST index or SP-GiST index (more effective for ranges)
-- https://www.postgresql.org/docs/current/spgist.html
CREATE INDEX idx_period_range ON tab USING GIST (tstzrange(period_begin, period_end, '[]'));
