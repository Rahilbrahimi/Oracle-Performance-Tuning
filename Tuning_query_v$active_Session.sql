---baresi top wait:
  SELECT AC.SQL_ID,
         AC.WAIT_CLASS,
         AC.WAIT_TIME,
         SS.EVENT,
         SP.OPERATION,
         SP.OPTIONS,
         SP.OBJECT_OWNER,
         SP.OBJECT_NAME,
         ds.USERNAME,
         SS.STATUS,
         AC.MODULE,
         AC.MACHINE
    FROM V$ACTIVE_SESSION_HISTORY AC
         JOIN V$SQL_PLAN SP ON AC.SQL_ID = SP.SQL_ID
         JOIN V$SESSION SS ON SS.USER# = AC.USER_ID
         JOIN DBA_USERS DS ON DS.USER_ID = AC.USER_ID 
   WHERE     SS.wait_class <> 'Idle' 
         AND AC.SAMPLE_TIME BETWEEN '09-AUG-25 10:16:10.856 AM'
                                AND '09-AUG-25 10:20:10.856 AM'
ORDER BY AC.WAIT_TIME DESC;

--aval time dba_hist_active_Sess_history ra check mikonim:

SELECT
    MIN(sample_time) AS oldest_sample,
    MAX(sample_time) AS newest_sample,
    (MAX(sample_time) - MIN(sample_time)) * 24 * 60 AS minutes_retained
FROM
    dba_hist_active_sess_history;
-----BARAYE dba_hist_active_Sess_history darim:

 SELECT AC.SQL_ID,
         AC.WAIT_CLASS,
         AC.WAIT_TIME,
         SS.EVENT,
         SP.OPERATION,
         SP.OPTIONS,
         SP.OBJECT_OWNER,
         SP.OBJECT_NAME,
         ds.USERNAME,
         SS.STATUS,
         AC.MODULE,
         AC.MACHINE
    FROM DBA_HIST_ACTIVE_SESS_HISTORY AC
         JOIN V$SQL_PLAN SP ON AC.SQL_ID = SP.SQL_ID
         JOIN V$SESSION SS ON SS.USER# = AC.USER_ID
         JOIN DBA_USERS DS ON DS.USER_ID = AC.USER_ID 
   WHERE     SS.wait_class <> 'Idle'  and ds.username ='ACCOUNT' 
         AND AC.SAMPLE_TIME BETWEEN '08-AUG-25 10:16:10.856 AM'
                                AND '09-AUG-25 10:20:10.856 AM'
ORDER BY AC.WAIT_TIME DESC;

----age ba user bekhahim bebinim:
 SELECT AC.SQL_ID,
         AC.WAIT_CLASS,
         AC.WAIT_TIME,
         SS.EVENT,
         SP.OPERATION,
         SP.OPTIONS,
         SP.OBJECT_OWNER,
         SP.OBJECT_NAME,
         ds.USERNAME,
         SS.STATUS,
         AC.MODULE,
         AC.MACHINE
    FROM V$ACTIVE_SESSION_HISTORY AC
         JOIN V$SQL_PLAN SP ON AC.SQL_ID = SP.SQL_ID
         JOIN V$SESSION SS ON SS.USER# = AC.USER_ID
         JOIN DBA_USERS DS ON DS.USER_ID = AC.USER_ID 
   WHERE     SS.wait_class <> 'Idle'  and ds.username ='ACCOUNT' 
         AND AC.SAMPLE_TIME BETWEEN '09-AUG-25 10:16:10.856 AM'
                                AND '09-AUG-25 10:20:10.856 AM'
ORDER BY AC.WAIT_TIME DESC;

----


----baraye CPU TIME:
---IN QUERY NESHOON MIDE KE KODOM SQL_ID DAR BEYNE BAZEYE MIN SAMPLE_TIME VA MAX SAMPLE_TIM CHEGHAD BE ZAMAN CPU DASHTE.

SELECT
    sql_id,
    sql_exec_id,
    MIN(sql_exec_start) AS exec_start_time,
    MIN(sample_time)    AS first_sample,
    MAX(sample_time)    AS last_sample,
    ROUND(SUM(TM_delta_cpu_time) / 1000000, 3) AS cpu_seconds,
    SUM(TM_delta_cpu_time) AS cpu_microseconds
FROM
    v$active_session_history
WHERE
    sql_exec_id IS NOT NULL
    AND sample_time 
        BETWEEN '09-AUG-25 10:16:10.856 AM'
                                AND '09-AUG-25 10:20:10.856 AM'
GROUP BY
    sql_id, sql_exec_id
ORDER BY
    cpu_seconds DESC;


	
	
----------va mohasebe hajm IO-----------------------------------------------
---userio wait time:

  SELECT
  sql_id,
  sql_exec_id,
  MIN(sql_exec_start)                                AS exec_start_time,
  MIN(sample_time)                                   AS first_sample,
  MAX(sample_time)                                   AS last_sample,
  ROUND(SUM(delta_read_io_bytes)  / 1024 / 1024, 2)  AS read_io_mb,
  ROUND(SUM(delta_write_io_bytes) / 1024 / 1024, 2)  AS write_io_mb,
  ROUND(
    (SUM(delta_read_io_bytes) + SUM(delta_write_io_bytes)) / 1024 / 1024, 2
  ) AS total_io_mb
FROM
  v$active_session_history
WHERE sample_time
   between 
       '06-AUG-25 10:20:10.856 AM'
                                AND '06-AUG-25 11:50:10.856 AM'-- AND SQL_ID ='4thz75n454knw'
 
  AND sql_exec_id IS NOT NULL
GROUP BY
  sql_id, sql_exec_id
ORDER BY
  total_io_mb DESC;
  
  --------------------------------------------
--baraye dba_hist_active_Sess_history:
    SELECT
  sql_id,
  sql_exec_id,
  MIN(sql_exec_start)                                AS exec_start_time,
  MIN(sample_time)                                   AS first_sample,
  MAX(sample_time)                                   AS last_sample,
  ROUND(SUM(delta_read_io_bytes)  / 1024 / 1024, 2)  AS read_io_mb,
  ROUND(SUM(delta_write_io_bytes) / 1024 / 1024, 2)  AS write_io_mb,
  ROUND(
    (SUM(delta_read_io_bytes) + SUM(delta_write_io_bytes)) / 1024 / 1024, 2
  ) AS total_io_mb
FROM
  DBA_HIST_ACTIVE_SESS_HISTORY
WHERE sample_time
BETWEEN '09-AUG-25 10:16:10.856 AM'
                                AND '09-AUG-25 10:20:10.856 AM' --AND SQL_ID ='4thz75n454knw'
 
  AND sql_exec_id IS NOT NULL
GROUP BY
  sql_id, sql_exec_id
ORDER BY
  total_io_mb DESC;
  
--------------------------------------------
-------------------------------TABLE_aCCESS_FULL:18-20 saniye zaman mibare.vali bar nemindaze.
---tooye baresi full table scan ha khyli mohem ke ama ghader ro check konim bebinim on jadavel ghadet shodan ya na.
---select * from dba_optstat_operations dss where dss.target='"MIFOSTENANTDEFAULT"."m_savings_account"' order by dss.end_time desc
WITH full_scans AS (
    SELECT
        a.sql_id,
        u.username,
        MIN(a.sample_time) AS first_sample,
        MAX(a.sample_time) AS last_sample,
        COUNT(*) AS samples,
        ROUND(COUNT(*) * 1, 2) AS ash_seconds -- هر نمونه 1 ثانیه
    FROM
        v$active_session_history a
        JOIN dba_users u
            ON a.user_id = u.user_id
    WHERE
        a.sample_time BETWEEN SYSDATE - 1/24 AND SYSDATE
        AND u.username NOT IN ('SYS','SYSTEM','DBSNMP','OUTLN','RAHELEH_E')
        AND a.session_type = 'FOREGROUND'
        AND EXISTS (
            SELECT 1
            FROM v$sql_plan p
            WHERE p.sql_id = a.sql_id
              AND p.operation = 'TABLE ACCESS'
              AND p.options = 'FULL'
              AND p.object_owner IS NOT NULL
        )
    GROUP BY
        a.sql_id, u.username
),
table_stats AS (
    SELECT owner, table_name, num_rows, blocks
    FROM dba_tables
)
SELECT
    f.sql_id,
    sp.object_owner,
    sp.object_name,
    f.username,
    f.first_sample,
    f.last_sample,
    f.samples,
    f.ash_seconds,
    ts.num_rows,
    ROUND((ts.blocks * 8) / 1024, 1) AS table_size_mb
FROM
    full_scans f
    JOIN v$sql_plan sp
        ON f.sql_id = sp.sql_id
       AND sp.operation = 'TABLE ACCESS'
       AND sp.options = 'FULL'
       AND sp.object_owner IS NOT NULL
    LEFT JOIN table_stats ts
        ON sp.object_owner = ts.owner
       AND sp.object_name = ts.table_name
WHERE
    ts.num_rows > 100000
ORDER BY
    f.samples DESC;
	
-------------------------------JADAVEL KOOCHIKI KE NESTED LOOP DARAN:
SELECT a.sql_id,
    p.object_owner,
    p.object_name,
    u.username,
    COUNT(*) AS fts_samples,
    MIN(a.sample_time) AS first_seen,
    MAX(a.sample_time) AS last_seen
FROM
    v$active_session_history a
    JOIN v$sql_plan p
        ON a.sql_id = p.sql_id
       AND a.sql_child_number = p.child_number
       AND p.operation = 'TABLE ACCESS'
       AND p.options  = 'FULL'
       AND p.object_owner IS NOT NULL
    JOIN dba_users u
        ON a.user_id = u.user_id
WHERE
    a.sample_time BETWEEN'09-AUG-25 10:16:10.856 AM'
                                AND '09-AUG-25 10:20:10.856 AM'
    AND u.username NOT IN ('SYS','SYSTEM','DBSNMP','OUTLN','RAHELEH_E')
    AND a.session_type = 'FOREGROUND'
    AND EXISTS (
        SELECT 1
        FROM v$sql_plan p2
        WHERE p2.sql_id = p.sql_id
          AND p2.child_number = p.child_number
          AND p2.id = p.parent_id
          AND p2.operation = 'NESTED LOOPS'
    )GROUP BY
    p.object_owner, p.object_name, u.username,a.sql_id
ORDER BY
    fts_samples DESC;
------------------elapsed_time:
SELECT DISTINCT
  ash.sql_id,
  ash.session_id,
  ash.session_serial#,
  ash.USER_ID,
  u.username,
  ash.sql_exec_id,
  MIN(ash.sample_time) AS exec_start_time,
  MAX(ash.sample_time) AS exec_end_time,
  (
    EXTRACT(SECOND FROM (MAX(ash.sample_time) - MIN(ash.sample_time)))

+ EXTRACT(MINUTE FROM (MAX(ash.sample_time) - MIN(ash.sample_time))) * 60
+ EXTRACT(HOUR   FROM (MAX(ash.sample_time) - MIN(ash.sample_time))) * 3600
+ EXTRACT(DAY    FROM (MAX(ash.sample_time) - MIN(ash.sample_time))) * 86400
  ) AS exec_duration_sec
FROM
  v$active_session_history ash
  JOIN dba_users u ON ash.USER_ID = u.USER_ID
WHERE
  ash.sql_id IS NOT NULL
  AND ash.sql_exec_id IS NOT NULL
  AND ash.sample_time >= SYSDATE - 1
  AND ash.USER_ID NOT IN (0)
  -- حذف user های سیستمی
  AND u.username NOT IN ('SYS', 'SYSTEM', 'DBSNMP', 'SYSMAN', 'OUTLN', 'MGMT_VIEW')
GROUP BY
  ash.sql_id, ash.session_id, ash.session_serial#, ash.sql_exec_id, ash.USER_ID, u.username
HAVING
  (
    EXTRACT(SECOND FROM (MAX(ash.sample_time) - MIN(ash.sample_time)))

+ EXTRACT(MINUTE FROM (MAX(ash.sample_time) - MIN(ash.sample_time))) * 60
+ EXTRACT(HOUR   FROM (MAX(ash.sample_time) - MIN(ash.sample_time))) * 3600
+ EXTRACT(DAY    FROM (MAX(ash.sample_time) - MIN(ash.sample_time))) * 86400
  ) > 60
ORDER BY
  exec_duration_sec DESC;
  
  
  
  
 
