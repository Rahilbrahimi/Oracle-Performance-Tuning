/**
 * =====================================================================
 * Profile Name: DERPT_LIMITED
 * Purpose    : To enforce security and resource consumption limits
 *              for the user DERPT in Oracle Database.
 * Type       : Oracle Profile (Password & Resource Management)
 * Scope      : RAC-Compatible (profile limits apply cluster-wide)
 * Author     : Milad
 * Created On : YYYY-MM-DD
 * =====================================================================
 *
 * 1. OVERVIEW
 *    Profiles in Oracle allow you to define:
 *      - Password Management Policies
 *      - Resource Consumption Limits
 *    This profile aims to:
 *      a) Enforce strong password policies for DERPT
 *      b) Limit session resource consumption
 *      c) Work with additional triggers/jobs (e.g., IOPS, PGA, Active Session)
 *
 * 2. PASSWORD MANAGEMENT PARAMETERS:
 *    FAILED_LOGIN_ATTEMPTS
 *        - Max consecutive failed login attempts before locking the user.
 *        - Security Impact: Prevents brute-force attempts.
 *
 *    PASSWORD_LIFE_TIME
 *        - Duration (in days) a password remains valid before expiration.
 *        - Forces periodic password change.
 *
 *    PASSWORD_REUSE_TIME / PASSWORD_REUSE_MAX
 *        - Controls re-usage of previous passwords.
 *        - Prevents quick cycling back to an old password.
 *
 *    PASSWORD_LOCK_TIME
 *        - Duration (days or fraction) an account stays locked after failed logins.
 *
 *    PASSWORD_GRACE_TIME
 *        - Grace period before account expiration after password expiry.
 *
 *    PASSWORD_VERIFY_FUNCTION
 *        - Calls a PL/SQL function to enforce complexity rules.
 *          Examples: VERIFY_FUNCTION_11G or custom implementation.
 *
 * 3. RESOURCE LIMIT PARAMETERS:
 *    SESSIONS_PER_USER
 *        - Max concurrent sessions per user.
 *        - Note: Counts all sessions (INACTIVE + ACTIVE).
 *
 *    CPU_PER_SESSION
 *        - Total CPU time allowed per session (in hundredths of seconds).
 *
 *    CPU_PER_CALL
 *        - CPU time allowed per SQL call (in hundredths of seconds).
 *
 *    CONNECT_TIME
 *        - Max duration (minutes) a session can remain connected.
 *
 *    IDLE_TIME
 *        - Max idle time (minutes) before session termination.
 *
 *    LOGICAL_READS_PER_SESSION / LOGICAL_READS_PER_CALL
 *        - Max logical reads per session/call.
 *        - Logical I/O measures buffer cache access.
 *
 *    PRIVATE_SGA
 *        - Limit for user-specific SGA memory allocation.
 *
 *    COMPOSITE_LIMIT
 *        - Weighted sum of all resource usage; advanced control across limits.
 *
 * 4. UNITS & SPECIAL VALUES:
 *    - Time limits: Days, hours (fraction of day), or minutes.
 *    - CPU limits: Hundredths of seconds.
 *    - Memory: Specify in bytes (default), K, M, or G.
 *    - Special constants:
 *        UNLIMITED     -> No restriction.
 *        DEFAULT       -> Inherit from DEFAULT profile.
 *
 * 5. USAGE & DEPLOYMENT:
 *    - CREATE PROFILE defines a new profile.
 *    - ALTER PROFILE modifies settings.
 *    - DROP PROFILE removes it (use CASCADE to drop from assigned users).
 *    - Assign profile to user:
 *          ALTER USER derpt PROFILE derpt_limited;
 *
 * 6. RAC CONSIDERATIONS:
 *    - Profile limits are enforced on each instance.
 *    - No GV$ dependency; native Oracle kernel enforcement.
 *
 * 7. RELATED CONTROLS OUTSIDE PROFILE:
 *    - Active Session Limit: Requires LOGON trigger with GV$SESSION.
 *    - PGA Limit: Custom trigger using GV$SESSTAT ('session pga memory').
 *    - IOPS Limit: Scheduler job + LOGON trigger; uses GV$SESSTAT deltas.
 *
 * =====================================================================
 */

CREATE PROFILE derpt_limited LIMIT
    -- Password Management
    FAILED_LOGIN_ATTEMPTS     5
    PASSWORD_LIFE_TIME        90
    PASSWORD_REUSE_TIME       365
    PASSWORD_REUSE_MAX        5
    PASSWORD_LOCK_TIME        1/24
    PASSWORD_GRACE_TIME       7
    PASSWORD_VERIFY_FUNCTION  verify_function_11g

    -- Resource Limits
    SESSIONS_PER_USER         10
    CPU_PER_SESSION           60000  
    CPU_PER_CALL              10000  
    CONNECT_TIME              480    
    IDLE_TIME                 30    
    LOGICAL_READS_PER_SESSION 100000
    LOGICAL_READS_PER_CALL    10000
    PRIVATE_SGA               10M
    COMPOSITE_LIMIT           5000000;

-- grant profile to user:
ALTER USER derpt PROFILE derpt_limited;
