/**Resource Management
 *sakhtar asli resource management 3 topic asli asat:
 *1.plan(resource plan)
 *2.Consumer GROUPS
 *3.Plan Directives
 *
 *baraye har taghir aval bayad yek pending area ijad konim.fazae ke taghirat dar an ijad mishe va bad dar nahayt validate va submit mishe.
*/

--pendig area:
BEGIN
  DBMS_RESOURCE_MANAGER.clear_pending_area;
  DBMS_RESOURCE_MANAGER.create_pending_area;
END;

/**
 *Consumer Group:gorohi ke karbaran session be an taalogh daran.
 *ravesh takhsis CPU beyne session ha.
 *1.ROUND ROUBIN:session ha be nobat cpu migiran
 *2.RUN-TO-COMPELATION:Session haye toolani zoodtar kamel mishan.
 *
 */

BEGIN
  DBMS_RESOURCE_MANAGER.create_consumer_group(
    consumer_group => 'OLTP',
    comment        => 'OLTP Applications');
END;

/**plan and plan directives:
 *plan tarif mikone ke chand group darim:
 *plan directive :sahm manabe har kodom ro moshakhas mikone.
 */
 
BEGIN
  DBMS_RESOURCE_MANAGER.create_plan_directive(
    plan                 => 'TEST_PLAN',
    group_or_subplan     => 'TEST_USER_CG',
    comment              => 'Limits for CPU, Active Session, PGA, Undo, Temp, I/O, Idle Time, Parallel',

    -- CPU
    MGMT_P1              => 50,        -- 50% CPU allocation
    UTILIZATION_LIMIT    => 60,        -- Max total CPU 60%

    -- Active Sessions
    ACTIVE_SESS_POOL_P1  => 5,         -- Max 5 active sessions
    QUEUEING_P1          => 30,        -- Timeout waiting in queue (sec)

    -- Memory
    SESSION_PGA_LIMIT    => 500,       -- Max PGA per session in MB
    UNDO_POOL            => 100000,    -- Max undo in KB
    MAX_TEMP_SPACE       => 50000,     -- Max Temp space in KB (50 MB)

    -- Idle Time
    MAX_IDLE_TIME        => 600,       -- Max 10 minutes idle
    MAX_IDLE_BLOCKER_TIME=> 300,       -- Max 5 minutes if blocking

    -- I/O
    SWITCH_IO_MEGABYTES  => 1000,      -- Max 1GB physical I/O
    SWITCH_IO_REQS       => 5000,      -- Max 5000 I/O requests
    SWITCH_IO_LOGICAL    => 20000,     -- Max 20000 logical I/O requests

    -- Parallel
    PARALLEL_DEGREE_LIMIT_P1 => 4,     -- Max parallel degree
    PARALLEL_SERVER_LIMIT    => 50,    -- Max 50% of parallel servers
    PARALLEL_QUEUE_TIMEOUT   => 60,    -- Max wait in parallel queue
    PARALLEL_STMT_CRITICAL   => FALSE, -- Parallel statements are not critical

    -- Optional: switch action 
    SWITCH_GROUP         => 'KILL_SESSION', 
    SWITCH_FOR_CALL      => TRUE
  );
END;
/


/**
 *Mapping Users to Consumer Groups:
 *taeen mikonim har user vared kodom group beshe
 *in kamelan daste on karbari hast ke dasteresi dare in kar anjam bede va on taeen mikone ke che user be che consumer group vasl beshe.
 */
 
 BEGIN
  DBMS_RESOURCE_MANAGER.set_consumer_group_mapping(
    attribute      => DBMS_RESOURCE_MANAGER.ORACLE_USER,
    value          => 'OE',
    consumer_group => 'OLTP');
END;

/**
 *dastoor grant_switch ejaze mide karbar beyne consumer_group ha switch kone.
 *masalan karbar user1 mitoone ba dastoor zir consumer group mored nazar ro be khodesh ekhtesas bede:
 *alter session set cosumer_group ='STAGE';
 *PAS DAR VAGHE TO BA IN GRANT BE KHODE KARBAR MOREDE NAZAR MITOONI IN EJAZE RO BEDI KE BERE TOOYE GROUP KE MIKHAD.
 */
BEGIN
  -- Assign users to consumer groups
    DBMS_RESOURCE_MANAGER_PRIVS.grant_switch_consumer_group(
    grantee_name   => 'USER1',
    consumer_group => 'STAGE',
    grant_option   => FALSE);
  DBMS_RESOURCE_MANAGER.set_initial_consumer_group('USER1', 'STAGE');
  
    DBMS_RESOURCE_MANAGER_PRIVS.grant_switch_consumer_group(
    grantee_name   => 'USER2',
    consumer_group => 'MART',
    grant_option   => FALSE);
  DBMS_RESOURCE_MANAGER.set_initial_consumer_group('USER2', 'MART');
  
END;
/
/**
 *
 *ba dastoor zir mitoonti grant rsource manager be taraf bedi ba dastoor zir masalan user DBA_USER khodesh mitoone plan besaze va ...
 */
 BEGIN
  DBMS_RESOURCE_MANAGER.GRANT_SYSTEM_PRIVILEGE(
    grantee_name   => 'DBA_USER',
    privilege_name => 'ADMINISTER_RESOURCE_MANAGER',
    admin_option   => TRUE
  );
END;
/





/**
 *mahdoodiyat ha:
 *hadaksar 28 consumer group dar yek plan mitoone active bashe.
 *yek plan hadaksar mitoone 28 child dashte bashe.
 *esme plan va consumer group nemitoone yeki bashe.
 */
 
 
 /**
  *taghsim bandi parameterha:
  *CPU & Management CPU :
   *MGMT1-MGMT8 :%CPU OR NESBAT CPU BEYNE GOROHA.
   *UTILIZATION_LIMIT:SAGHF MASRAF CPU BARAYE GOROH.HATA AGE CPU EZAFE AZAD BESHE.
  *ACTIVE_SESSION_POOL
   *ACTIVE_SESS_POOL_P1:HADAKSAR TEDAD SESSION HAYE ACTIVE BARAAYE GROUP
   *QUEUEING_P1:ZAMAN ENTEZAR SESSION DAR QUEUE GHABL AZ TIMEOUT.
  *PARALLEL EXCEUTON:
   *PARALLEL_DEGREE_LIMIT_P1:Maximum parallel degree
   *PARALLEL_QUEUE_TIMEOUT:bishtarin zaman entezar baraye vorod be saf parallel
   *PARALLEL_SERVER_LIMIT:darsad hadaksar estefade az server haye parallel
   *PARALLEL_STMT_CRITICAL:Moshakhas mikone query haye parallel hayati hastan ya na.(agar yes bashe az saf obor mikonan ta mostaghim ejra beshan).
  *PGA/Memory/ando session.
   *SESSION_PGA_LIMIT:hadaksar PGA baraye har session
   *UNDO_POOL:hadaksar undo mojaz(kb)
  *IDLE MANAGEMENT:
   *MAX_IDLE_TIME:Hadaksar zaman bikari session
   *MAX_IDLE_BLOCKER_TIME:Hadaksar zamani bikari session baraye session ke blocker hast.
  *SWITCHING RULES:
   *SWITCHING GROUP:
    *CANSEL QUERY:QUERY CANSEL mishe.
	*KILL SESSION:SESSION KILL MISHE.
	*LOG ONLY :FAGHAT LOG SABT MISHE.
   *SWITCH_TIME:HADKASAR ZAMAN CPU BARAYE YEK QUERY GHABL AZ INKE ACTION ANJAM BESHE.
   *SWITCH_ESTIMATE:AGAR TRUE BASHE GHABL AZ SHORO QUERY BARESI MISHE AYA GHARAR BISHTAR AZ SWITCH_TIME tool bekeshe ya na.
   *MAX_EST_EXEC_TIME:agar optimizer takhmin bezane bishtar az in zaman cpu tool mikeshe aslan ejra nemishe.
   *SWITCH_IO_MEGABYTES:hadaksar MB read/write ghabl az action.
   *SWITCH_IO_REQS:tedad IO request ha ghabl az action
   *SWITCH_IO_LOGICAL:tedad logical IO ghabl az action
   *SWITCH_ELAPSED_TIME:MODAT Zaman vaghei ghabl az action
   *SWITCH FOR CALL:Moshakhas mikone bad etmam query session bargharde be cunsomer group asli ya na
  *IO LIMIT:
   *SWITCH_IO_REQUEST
   *SWITCH_IO_MEGHABYTE.
*in oracle 19 c parameter:
PLAN
GROUP
COMMENT
CPU_P1
CPU_P2
CPU_P3
CPU_P4
CPU_P5
CPU_P6
CPU_P7
CPU_P8
ACTIVE_SESS_POOL_P1
QUEUEING_P1
PARALLEL_DEGREE_LIMIT_P1
SWITCH_GROUP
SWITCH_TIME,
SWITCH_ESTIMATE
MAX_EST_EXEC_TIME
UNDO_POOL
MAX_IDLE_TIME
MAX_IDLE_BLOCKER_TIME
SWITCH_TIME_IN_CALL
MGMT_P1
MGMT_P2
MGMT_P3
MGMT_P4
MGMT_P5
MGMT_P6
MGMT_P7
MGMT_P8
SWITCH_IO_MEGABYTES
SWITCH_IO_REQS
SWITCH_FOR_CALL
MAX_UTILIZATION_LIMIT  *saghf estefade cpu motlagh goroh.masalan bozrghtar az 60 yani :majmoo masraf cpu tahte hich sharayeti nemitoone bishtar az 60 darsad bashe,
PARALLEL_TARGET_PERCENTAGE
PARALLEL_QUEUE_TIMEOUT
PARALLEL_SERVER_LIMIT
UTILIZATION_LIMIT --*saghf estefade dar sath takhsisha va sharayet adi.
SWITCH_IO_LOGICAL
SWITCH_ELAPSED_TIME
SHARES
PARALLEL_STMT_CRITICAL
SESSION_PGA_LIMIT
PQ_TIMEOUT_ACTION

* be soorat koli:
PGA → SESSION_PGA_LIMIT

Undo → UNDO_POOL

CPU → MGMT_P1..P8, UTILIZATION_LIMIT, MAX_UTILIZATION_LIMIT

Active sessions → ACTIVE_SESS_POOL_P1

Parallel → PARALLEL_DEGREE_LIMIT_P1, PARALLEL_SERVER_LIMIT, PARALLEL_QUEUE_TIMEOUT, PARALLEL_TARGET_PERCENTAGE

I/O → SWITCH_IO_MEGABYTES, SWITCH_IO_REQS, SWITCH_IO_LOGICAL

Idle time → MAX_IDLE_TIME, MAX_IDLE_BLOCKER_TIME

Execution/call switching → SWITCH_GROUP, SWITCH_TIME, SWITCH_ESTIMATE, SWITCH_FOR_CALL, PQ_TIMEOUT_ACTION

*/
-- همه Resource Planها
SELECT * FROM DBA_RSRC_PLANS;

-- همه Directives هر Plan
SELECT * FROM DBA_RSRC_PLAN_DIRECTIVES
WHERE PLAN = 'TEST_PLAN';

-- همه Consumer Groupها
SELECT * FROM DBA_RSRC_CONSUMER_GROUPS;

-- Mapping کاربران
SELECT * FROM DBA_RSRC_CONSUMER_GROUP_PRIVS;

-- 
SELECT username, resource_consumer_group
FROM v$session
WHERE username = 'TEST_USER';

select * from v$version;
SELECT argument_name, data_type, in_out
FROM all_arguments
WHERE object_name = 'CREATE_PLAN_DIRECTIVE'
  AND package_name = 'DBMS_RESOURCE_MANAGER'
ORDER BY sequence;

   
  