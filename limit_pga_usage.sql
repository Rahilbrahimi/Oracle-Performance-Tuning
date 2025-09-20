/**
 * Trigger Name: limit_pga_usage_derpt
 * 
 * Description:
 * Enforces a maximum PGA memory usage limit for user DERPT in an Oracle RAC 
 * environment. The trigger checks the current session's PGA usage immediately 
 * after login and aborts the session if it exceeds the defined threshold.
 * 
 * Environment:
 * - Oracle Database with RAC.
 * - Requires access to GV$SESSTAT and GV$STATNAME views.
 * 
 * Trigger Event:
 * AFTER LOGON ON DATABASE
 * 
 * Logic:
 * 1. Verify that the connected user is DERPT.
 * 2. Retrieve the PGA memory usage for the current session from GV$SESSTAT 
 *    joined with GV$STATNAME (statistic name = 'session pga memory').
 * 3. Compare the usage against the limit (200 MB in this example).
 * 4. If exceeded, raise an application error (-20002) to block the session.
 * 
 * Permissions:
 * - Must be created by SYS or a user with ADMINISTER DATABASE TRIGGER privilege.
 * - Requires SELECT privilege on GV$SESSTAT and GV$STATNAME.
 * 
 * Customization:
 * - To change the user, replace 'DERPT' in the condition.
 * - To adjust the memory limit, modify the constant v_limit_bytes.
 * 
 * Limitations:
 * - Only checks at login; does not monitor ongoing sessions.
 * - For continuous monitoring, implement a Scheduler Job.
 */
CREATE OR REPLACE TRIGGER limit_pga_usage_derpt
AFTER LOGON ON DATABASE
DECLARE
    v_pga_usage_bytes NUMBER;
    v_limit_bytes     CONSTANT NUMBER := 200 * 1024 * 1024; -- 200 MB
BEGIN
    -- Run only for DERPT
    IF UPPER(SYS_CONTEXT('USERENV', 'SESSION_USER')) = 'DERPT' THEN
        -- Get current session's PGA usage across RAC
        SELECT s.value
        INTO v_pga_usage_bytes
        FROM GV$SESSTAT s
             JOIN GV$STATNAME n 
               ON s.INST_ID = n.INST_ID
              AND s.statistic# = n.statistic#
        WHERE n.name = 'session pga memory'
          AND s.SID = SYS_CONTEXT('USERENV', 'SID')
          AND s.INST_ID = SYS_CONTEXT('USERENV', 'INSTANCE');

        -- Check limit
        IF v_pga_usage_bytes > v_limit_bytes THEN
            RAISE_APPLICATION_ERROR(
                -20002,
                'PGA usage exceeded limit of 200 MB for user DERPT.'
            );
        END IF;
    END IF;
END;
/
