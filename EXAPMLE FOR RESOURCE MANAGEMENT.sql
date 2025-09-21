BEGIN
  DBMS_RESOURCE_MANAGER.CLEAR_PENDING_AREA;
 end;
 begin
  DBMS_RESOURCE_MANAGER.CREATE_PENDING_AREA;
end;

BEGIN
  DBMS_RESOURCE_MANAGER.create_plan(
    plan    => 'TEST_PLAN',
    comment => 'Plan for test_user with all resource limits',
    mgmt_mth => 'EMPHASIS'   
  );
END;
/




BEGIN
  DBMS_RESOURCE_MANAGER.create_consumer_group(
    consumer_group => 'TEST_USER_CG',
    comment        => 'Consumer group for test_user with full resource limits'
  );
END;
/

BEGIN
  DBMS_RESOURCE_MANAGER.create_plan_directive(
    plan                  => 'TEST_PLAN',
    group_or_subplan      => 'TEST_USER_CG',
    comment               => 'Limits for CPU, Active Sessions, PGA, Undo, Idle, Parallel, I/O, Cancel SQL Action',

    -- CPU
    MGMT_P1               => 50,       -- 50% CPU allocation at level 1
    UTILIZATION_LIMIT     => 60,       -- Max total CPU 60%
    MAX_UTILIZATION_LIMIT => 60,       -- Absolute max 60%

    -- Active Sessions
    ACTIVE_SESS_POOL_P1   => 5,        -- Max 5 active sessions
    QUEUEING_P1           => 30,       -- Timeout waiting in queue (seconds)

    -- Memory
    SESSION_PGA_LIMIT     => 500,      -- Max PGA per session (MB)
    UNDO_POOL             => 100000,   -- Max undo in KB

    -- Idle Time
    MAX_IDLE_TIME         => 600,      -- Max idle time in seconds
    MAX_IDLE_BLOCKER_TIME => 300,      -- Max idle time if blocking

    -- Parallel Execution
    PARALLEL_DEGREE_LIMIT_P1 => 4,     -- Max degree of parallelism
    PARALLEL_SERVER_LIMIT    => 50,    -- Max 50% of parallel servers
    PARALLEL_QUEUE_TIMEOUT   => 60,    -- Max wait in parallel queue
    PARALLEL_TARGET_PERCENTAGE => 50,  -- Target % of parallel execution resources
    PARALLEL_STMT_CRITICAL  => 'FALSE',-- Statements not critical

    -- I/O Limits
    SWITCH_IO_MEGABYTES     => 1000,   -- Max 1 GB physical I/O
    SWITCH_IO_REQS          => 5000,   -- Max 5000 I/O requests
    SWITCH_IO_LOGICAL       => 10000,  -- Max logical I/O requests

    -- Switch / Action
    SWITCH_GROUP            => 'CANCEL_SQL', -- Cancel SQL if limits exceeded
    SWITCH_FOR_CALL         => TRUE,         -- Return to original group after top-level call

    -- Time-based limits
    SWITCH_TIME             => 300,     -- Max CPU seconds per call before switch
    SWITCH_ESTIMATE         => TRUE,    -- Use estimated execution time
    SWITCH_ELAPSED_TIME     => 600,     -- Elapsed time in seconds before action
    MAX_EST_EXEC_TIME       => 1800,    -- Max estimated execution time

    -- Shares (CDB / PDB)
    SHARES                  => 10,      -- Resource share for this group

    -- Optional / Deprecated
    PQ_TIMEOUT_ACTION       => 'CANCEL' -- Parallel Queue timeout action
  );
END;
/

--MAPPING:
BEGIN
  DBMS_RESOURCE_MANAGER.SET_CONSUMER_GROUP_MAPPING(
    ATTRIBUTE      => DBMS_RESOURCE_MANAGER.ORACLE_USER,
    VALUE          => 'TEST_USER',
    CONSUMER_GROUP => 'TEST_USER_CG'
  );
END;
/

BEGIN
  DBMS_RESOURCE_MANAGER.create_plan_directive(
    plan              => 'TEST_PLAN',
    group_or_subplan  => 'OTHER_GROUPS',
    comment           => 'Default directive for other sessions',
    MGMT_P1           => 50 
  );
END;
/



BEGIN
  DBMS_RESOURCE_MANAGER.validate_pending_area;
  DBMS_RESOURCE_MANAGER.submit_pending_area;
END;
/



BEGIN
  DBMS_RESOURCE_MANAGER.validate_pending_area;

  DBMS_RESOURCE_MANAGER.submit_pending_area;
END;
/

ALTER SYSTEM SET RESOURCE_MANAGER_PLAN = TEST_PLAN;


/**
 *baraye tesy active_Session va timeout:
 */
 
 --in job ro ejra kon:
 BEGIN
  FOR i IN 1..5 LOOP
    DBMS_SCHEDULER.CREATE_JOB(
      job_name        => 'TEST_USER_JOB_' || i,
      job_type        => 'PLSQL_BLOCK',
      job_action      => q'[
        DECLARE
          v_count NUMBER := 0;
          v_start TIMESTAMP := SYSTIMESTAMP;
        BEGIN
          WHILE SYSTIMESTAMP < v_start + INTERVAL '3' MINUTE LOOP
            v_count := v_count + POWER(DBMS_RANDOM.VALUE, 2);
          END LOOP;
          DBMS_OUTPUT.PUT_LINE('Done: ' || v_count);
        END;
      ]',
      start_date      => SYSTIMESTAMP,
      enabled         => TRUE,
      auto_drop       => true,
      comments        => 'CPU intensive test for active session limit'
    );
  END LOOP;
END;
/

---hala dar yek session dg yek query say kon ejra koni:
SELECT *
FROM   user_scheduler_running_jobs;

SELECT job_name, state, last_start_date, last_run_duration
FROM dba_scheduler_jobs
WHERE job_name = 'TEST_USER_JOB_';

----[Error] Execution (1: 1): ORA-07454: queue timeout, 30 second(s), exceeded 
--in khata bayad dide beshe.

SELECT sid, serial#, username, status, program, machine, sql_id, resource_consumer_group, logon_time
FROM   v$session
WHERE  username = 'TEST_USER'
ORDER BY status DESC, sid;



SELECT resource_consumer_group,
       COUNT(*) AS total_sessions,
       SUM(CASE WHEN status='ACTIVE' THEN 1 ELSE 0 END) AS active_sessions,
       SUM(CASE WHEN status='INACTIVE' THEN 1 ELSE 0 END) AS inactive_sessions
FROM   v$session
GROUP BY resource_consumer_group;


---ejraye query zir ora dad be dalil mahdoodiyat SWITCH_IO_LOGICAL => 10000

CREATE TABLE test_parallel2 AS
SELECT * FROM dba_objects CONNECT BY LEVEL <= 100;

--rror] Execution (2: 15): ORA-56733: logical I/O limit exceeded - call aborted



----baraye chek kardan parallel ham mitoonim query zir ra anjam bedim :
SELECT /*+ parallel(test_parallel 4) */ COUNT(*)
FROM test_parallel;

---va sepas az v$sql_monitor soton PX_MAXDOP tedad parallel ekhtesas yafte ra check konim.





