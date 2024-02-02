-- TASK 2


CREATE TABLE table_to_delete AS
SELECT 'veeeeeeery_long_string' || x AS col
FROM generate_series(1,(10^7)::int) x; -- generate_series() creates 10^7 rows of sequential numbers from 1 to 10000000 (10^7)


SELECT *, pg_size_pretty(total_bytes) 
AS total, pg_size_pretty(index_bytes) AS INDEX,
pg_size_pretty(toast_bytes) AS toast,
pg_size_pretty(table_bytes) AS TABLE
	FROM ( SELECT *, total_bytes-index_bytes-COALESCE(toast_bytes,0) AS table_bytes
			FROM(SELECT
	c.oid,nspname AS table_schema,
relname AS TABLE_NAME,
c.reltuples AS row_estimate, pg_total_relation_size(c.oid) AS total_bytes, pg_indexes_size(c.oid) AS index_bytes, pg_total_relation_size(reltoastrelid) AS toast_bytes
FROM pg_class c
LEFT JOIN pg_namespace n ON n.oid = c.relnamespace WHERE relkind = 'r'
) a
)a
WHERE table_name LIKE '%table_to_delete%';
-- 602 357 760 bytes
-- after next query 602 554 368 bytes
-- after vacuum 401 571 840 bytes


DELETE FROM table_to_delete
WHERE REPLACE(col, 'veeeeeeery_long_string','')::int % 3 = 0; -- removes 1/3 of all rows
 -- 11 351 ms 


VACUUM FULL VERBOSE table_to_delete;

/*
 * What is the difference between TRUNCATE and DELETE? When is it better to use each of them
 * 
 * TRUNCATE is used to delete all data from table without checking information. It can be very dangerous to use it, especially with 
 * CASCADE option when all data in linked tables will be deleted, so that unpredictable number of tables can be affected by accident
 * DELETE is used to delete certain rows and is commonly used with WHERE clause and information about every deleted 
 * row will be saved in transaction so that's why DELETE consumes resources of a computer depending on number of rows delted. 
 * It is better to use TRUNCATE when we do not care about information in table
 * DELETE is applied when we need to delete certain rows keeping the rest
*/

