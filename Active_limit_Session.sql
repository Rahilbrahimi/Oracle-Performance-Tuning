----
/*
===============================================================================
SYS_CONTEXT Function – Internal Documentation
===============================================================================
Description:
    Retrieves environment and session information from Oracle Database.
    Useful for security triggers, auditing, and resource enforcement.

Syntax:
    SYS_CONTEXT(namespace, parameter [, length])

Common USERENV Parameters:
    - SESSION_USER
    - CURRENT_USER
    - SID
    - INSTANCE
    - IP_ADDRESS
    - HOST
    - TERMINAL

Example:
    SELECT SYS_CONTEXT('USERENV', 'SID'),
           SYS_CONTEXT('USERENV', 'INSTANCE')
      FROM dual;
===============================================================================
*/

/**CREATE OR REPLACE TRIGGER limit_pga_usage_derpt
 *AFTER LOGON ON DATABASE
 */

...

/**
 * Trigger Name: limit_active_sessions_derpt
 * 
 * Description:
 * Limits the number of active sessions for user DERPT across all instances
 * in an Oracle Real Application Clusters (RAC) environment. If the number of 
 * active sessions (STATUS = 'ACTIVE') reaches or exceeds 5, the logon attempt 
 * is blocked with a custom Oracle error code.
 * 
 * Environment:
 * - Oracle Database with RAC configuration.
 * - Requires access to GV$SESSION for querying sessions across all instances.
 * 
 * Trigger Event:
 * AFTER LOGON ON DATABASE
 * - Executes immediately after a successful authentication attempt, 
 *   before allowing the session to proceed.
 * 
 * Logic:
 * 1. Checks if the current session belongs to the user DERPT using 
 *    SYS_CONTEXT('USERENV', 'SESSION_USER').
 * 2. Counts all ACTIVE sessions for that user in GV$SESSION across all 
 *    instances, excluding the current session (SID & INST_ID filters).
 * 3. If the count is greater than or equal to 5, the trigger raises 
 *    an application error (-20001) and aborts the logon.
 * 
 * Security & Permissions:
 * - This trigger must be created by a user with adequate privileges,
 *   typically SYS or any user with ADMINISTER DATABASE TRIGGER privilege.
 * - The creator must have SELECT privileges on GV$SESSION.
 * 
 * Customization:
 * - To change the limit, modify the numeric constant in the IF condition (>= 5).
 * - To target a different user, replace 'DERPT' with the desired username 
 *   in both the IF check and GV$SESSION query.
 * 
 * Limitations:
 * - This trigger enforces limits across RAC instances but does not 
 *   differentiate by session type (e.g., background vs foreground sessions).
 * - May block necessary maintenance sessions if misconfigured.
 * 
 * Author:Raheleh Ebrahimi
 * Date: 2025/09/19
 */
CREATE OR REPLACE TRIGGER limit_active_sessions_derpt
AFTER LOGON ON DATABASE
DECLARE
    v_active_sessions NUMBER;
BEGIN
    -- Run trigger only for user DERPT
    IF UPPER(SYS_CONTEXT('USERENV', 'SESSION_USER')) = 'DERPT' THEN
        
        -- Count all ACTIVE sessions for DERPT across all RAC instances,
        -- excluding the current session (identified by SID and INST_ID)
        SELECT COUNT(*)
        INTO v_active_sessions
        FROM GV$SESSION
        WHERE USERNAME = 'DERPT'
          AND STATUS = 'ACTIVE'
          AND NOT (
              SID = SYS_CONTEXT('USERENV', 'SID') 
              AND INST_ID = SYS_CONTEXT('USERENV', 'INSTANCE')
          );

        -- Enforce the limit
        IF v_active_sessions >= 5 THEN
            RAISE_APPLICATION_ERROR(
                -20001,
                'Active session limit (5) exceeded for user DERPT.'
            );
        END IF;
    END IF;
END;
/
