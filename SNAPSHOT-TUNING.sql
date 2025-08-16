---Snapshot query:
--Top wait in Snapshot:
---ba filter rooye snap_id beyne do snapshot moghayese shode.
--BARAYE PEYDA KARDAN SHOMARE SNAP_ID KE DAR QUERY HA BA START_SNAP VA END_SNAP BE KAR RAFTE BAR ASAS TIME KE MIKHAID AZ QUERY ZIR ESTEFADE MIKONIM:
SELECT snap_id, begin_interval_time, end_interval_time
FROM dba_hist_snapshot
WHERE begin_interval_time BETWEEN TO_DATE('2025-08-06 10:20:00', 'YYYY-MM-DD HH24:MI:SS')
                            AND TO_DATE('2025-08-06 11:50:00', 'YYYY-MM-DD HH24:MI:SS')
ORDER BY snap_id;
---be dalil por hazine boodan va join ghyre zaroor behtar aval shomare snap_id ra begirim.
---------------------------
SELECT 
    event,
    wait_class,
    COUNT(*) AS wait_count
FROM
    dba_hist_active_sess_history
WHERE
    wait_class <> 'Idle'
    AND snap_id BETWEEN :start_snap AND :end_snap
GROUP BY
    event, wait_class
ORDER BY
    wait_count DESC
FETCH FIRST 10 ROWS ONLY;
----LIST SESSIONHA KE DAR BAZE KHASI WAIT DASHTAN VA OBJECT_NAMEHA:
SELECT
    AC.sql_id,
    AC.wait_class,
    AC.time_waited,
    AC.event,
    SP.operation,
    SP.options,
    SP.object_owner,
    SP.object_name,
    DS.username,
    AC.module,
    AC.machine
FROM
    dba_hist_active_sess_history AC
    JOIN dba_hist_sql_plan SP
      ON AC.sql_id = SP.sql_id
     AND AC.dbid = SP.dbid
     AND AC.plan_hash_value = SP.plan_hash_value
    JOIN dba_users DS
      ON AC.user_id = DS.user_id
WHERE
    AC.wait_class <> 'Idle'
    AND AC.snap_id BETWEEN :start_snap AND :end_snap
ORDER BY
    AC.time_waited DESC;

---BARESI WAIT CPU:
SELECT
    sql_id,
    sql_exec_id,
    MIN(sql_exec_start) AS exec_start_time,
    MIN(sample_time)    AS first_sample,
    MAX(sample_time)    AS last_sample,
    ROUND(SUM(tm_delta_cpu_time) / 1000000, 3) AS cpu_seconds,
    SUM(tm_delta_cpu_time) AS cpu_microseconds
FROM
    dba_hist_active_sess_history
WHERE
    sql_exec_id IS NOT NULL
    AND snap_id BETWEEN :start_snap AND :end_snap
GROUP BY
    sql_id, sql_exec_id
ORDER BY
    cpu_seconds DESC;
-------------------------------------------------
--------------------------------------------------------cpu time:
SELECT
    sql_id,
    sql_exec_id,
    MIN(sql_exec_start) AS exec_start_time,
    MIN(sample_time)    AS first_sample,
    MAX(sample_time)    AS last_sample,
    ROUND(SUM(tm_delta_cpu_time) / 1000000, 3) AS cpu_seconds,
    SUM(tm_delta_cpu_time) AS cpu_microseconds
FROM
    dba_hist_active_sess_history
WHERE
    sql_exec_id IS NOT NULL
    AND snap_id BETWEEN :start_snap AND :end_snap
GROUP BY
    sql_id, sql_exec_id
ORDER BY
    cpu_seconds DESC;
	
	----------------------------IO WAIT:
	SELECT
    sql_id,
    MIN(snap_id) AS start_snap,
    MAX(snap_id) AS end_snap,
    ROUND(SUM(buffer_gets_delta) / 1024, 2) AS buffer_gets_k,
    ROUND(SUM(disk_reads_delta) / 1024, 2) AS disk_reads_k,
    ROUND(SUM(read_io_delta) / 1024 / 1024, 2) AS read_io_mb,
    ROUND(SUM(write_io_delta) / 1024 / 1024, 2) AS write_io_mb,
    ROUND(SUM(read_io_delta + write_io_delta) / 1024 / 1024, 2) AS total_io_mb,
    SUM(executions_delta) AS executions
FROM
    dba_hist_sqlstat
WHERE
    snap_id BETWEEN :start_snap AND :end_snap
GROUP BY
    sql_id
ORDER BY
    total_io_mb DESC;

---------------------------table access full:
WITH full_scans AS (
    SELECT DISTINCT
        ash.sql_id,
        du.username,
        MIN(ash.sample_time) AS first_sample,
        MAX(ash.sample_time) AS last_sample,
        COUNT(*) AS samples,
        ROUND(COUNT(*) * 1, 2) AS ash_seconds -- فرض هر sample یک ثانیه است
    FROM
        dba_hist_active_sess_history ash
        JOIN dba_users du
            ON ash.user_id = du.user_id
    WHERE
        ash.snap_id BETWEEN :start_snap AND :end_snap
        AND du.username NOT IN ('SYS','SYSTEM','DBSNMP','OUTLN','RAHELEH_E')
        AND ash.session_type = 'FOREGROUND'
        AND EXISTS (
            SELECT 1
            FROM dba_hist_sql_plan p
            WHERE p.sql_id = ash.sql_id
              AND p.operation = 'TABLE ACCESS'
              AND p.options = 'FULL'
              AND p.object_owner IS NOT NULL
        )
    GROUP BY
        ash.sql_id, du.username
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
    JOIN dba_hist_sql_plan sp
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
---------------------------------------------
-----query hae ke dar anha nested loop vojod dare:
WITH nested_loop_sqls AS (
    SELECT DISTINCT
        ash.sql_id,
        du.username,
        MIN(ash.sample_time) AS first_sample,
        MAX(ash.sample_time) AS last_sample,
        COUNT(*) AS samples,
        ROUND(COUNT(*) * 1, 2) AS ash_seconds -- فرض هر sample یک ثانیه است
    FROM
        dba_hist_active_sess_history ash
        JOIN dba_users du ON ash.user_id = du.user_id
    WHERE
        ash.snap_id BETWEEN :start_snap AND :end_snap
        AND du.username NOT IN ('SYS','SYSTEM','DBSNMP','OUTLN','RAHELEH_E')
        AND ash.session_type = 'FOREGROUND'
        AND EXISTS (
            SELECT 1
            FROM dba_hist_sql_plan p
            WHERE p.sql_id = ash.sql_id
              AND p.operation = 'NESTED LOOPS'
        )
    GROUP BY
        ash.sql_id, du.username
),
table_stats AS (
    SELECT owner, table_name, num_rows, blocks
    FROM dba_tables
)
SELECT
    n.sql_id,
    sp.object_owner,
    sp.object_name,
    n.username,
    n.first_sample,
    n.last_sample,
    n.samples,
    n.ash_seconds,
    ts.num_rows,
    ROUND((ts.blocks * 8) / 1024, 1) AS table_size_mb
FROM
    nested_loop_sqls n
    JOIN dba_hist_sql_plan sp ON n.sql_id = sp.sql_id
       AND sp.operation = 'TABLE ACCESS'
       AND sp.options = 'FULL'
       AND sp.object_owner IS NOT NULL
    LEFT JOIN table_stats ts ON sp.object_owner = ts.owner AND sp.object_name = ts.table_name
WHERE
    ts.num_rows IS NOT NULL
ORDER BY
    n.samples DESC;
	
	
-----elapsed_Time:
SELECT 
    ss.sql_id,
    sn.begin_interval_time,
    sn.end_interval_time,
    ss.executions_delta,
    ROUND(ss.elapsed_time_delta / NULLIF(ss.executions_delta, 0) / 1e6, 4) AS sec_per_exec
FROM 
    dba_hist_sqlstat ss
    JOIN dba_hist_snapshot sn 
        ON ss.snap_id = sn.snap_id 
        AND ss.instance_number = sn.instance_number
WHERE 
    ss.sql_id = 'bhbbpwdqppdcm'
    AND sn.begin_interval_time 
       BETWEEN  '04-AUG-25 10:20:10.856 AM'
                                AND '05-AUG-25 10:20:10.856 AM'
ORDER BY 
    sec_per_exec DESC;
	
	------------------
	
SELECT DISTINCT sql_id
FROM (
  SELECT
    sql_id,
    (
      EXTRACT(SECOND FROM (MAX(sample_time) - MIN(sample_time))) +
      EXTRACT(MINUTE FROM (MAX(sample_time) - MIN(sample_time))) * 60 +
      EXTRACT(HOUR   FROM (MAX(sample_time) - MIN(sample_time))) * 3600 +
      EXTRACT(DAY    FROM (MAX(sample_time) - MIN(sample_time))) * 86400
    ) AS exec_duration_sec
  FROM
    dba_hist_active_sess_history
  WHERE
    sql_id IS NOT NULL
    AND sql_exec_id IS NOT NULL
    AND sample_time >= SYSDATE - 1 
    AND USER_ID NOT IN (0)
  GROUP BY
    sql_id, session_id, session_serial#, sql_exec_id, USER_ID
  HAVING
    (
      EXTRACT(SECOND FROM (MAX(sample_time) - MIN(sample_time))) +
      EXTRACT(MINUTE FROM (MAX(sample_time) - MIN(sample_time))) * 60 +
      EXTRACT(HOUR   FROM (MAX(sample_time) - MIN(sample_time))) * 3600 +
      EXTRACT(DAY    FROM (MAX(sample_time) - MIN(sample_time))) * 86400
    ) > 60
);

-------

