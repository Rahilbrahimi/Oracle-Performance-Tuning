---RESOURCE MANAGEMENT:

/**
 * STEP1:CREATE PROFILE $ CREATE USER.:
 
 */
 
 ----1:First we create a pending area.
BEGIN
  DBMS_RESOURCE_MANAGER.clear_pending_area;
END;
/

---2:Next we create a plan.

BEGIN
  DBMS_RESOURCE_MANAGER.create_plan(
    plan    => 'hybrid_plan',
    comment => 'Plan for a combination of high and low priority tasks.');
END;
/

---2-test
EXEC DBMS_RESOURCE_MANAGER.CREATE_PLAN(
  plan    => 'tes_plan',
  comment => 'Resource plan for TES user');
end;
/





--3:Then we create a web and a batch consumer group.
BEGIN
  DBMS_RESOURCE_MANAGER.create_consumer_group(
    consumer_group => 'WEB_CG',
    comment        => 'Web based OTLP processing - high priority');

  DBMS_RESOURCE_MANAGER.create_consumer_group(
    consumer_group => 'BATCH_CG',
    comment        => 'Batch processing - low priority');
END;
/


---3-test:
EXEC DBMS_RESOURCE_MANAGER.CREATE_CONSUMER_GROUP(
  consumer_group => 'TES_CG',
  comment        => 'Consumer group for TES user');
  
end;
/




------
EXEC DBMS_RESOURCE_MANAGER.CREATE_PLAN_DIRECTIVE(
  plan                   => 'tes_plan',
  group_or_subplan       => 'TES_CG',
  comment                => 'Limit TES user resources',
  cpu_p1                 => 50,   -- حداکثر 50% CPU
  active_sess_pool_p1    => 2,    -- حداکثر 2 active session
  parallel_degree_limit_p1 => 2,  -- حداکثر degree موازی 2
  max_iops               => 500,  -- حداکثر 500 عملیات I/O در ثانیه
  max_mbps               => 20,   -- حداکثر 20 MBps
  max_utilization_limit  => 200); -- حداکثر 200MB مصرف TEMP
-------

BEGIN
  DBMS_RESOURCE_MANAGER.create_plan_directive(
    plan                   => 'test_plan',
    group_or_subplan       => 'TEST_USER_CG',
    comment                => 'Limit all resources for TEST_USER',
    cpu_p1                 => 50,    -- حداکثر 50% CPU
    active_sess_pool_p1    => 2,     -- حداکثر 2 active session
    parallel_degree_limit_p1 => 2,   -- حداکثر degree موازی 2
    max_iops               => 500,   -- حداکثر 500 عملیات I/O
    max_mbps               => 20,    -- حداکثر 20 MBps
    max_utilization_limit  => 200);  -- حداکثر مصرف TEMP به MB
END;
/




--1 takhsisi dadan faza:

BEGIN
  DBMS_RESOURCE_MANAGER.clear_pending_area;
 DBMS_RESOURCE_MANAGER.create_pending_area;
END;
/
---2:create plan:
BEGIN
  DBMS_RESOURCE_MANAGER.create_plan(
    plan    => 'Test_plan',
    comment => 'Resource plan for TES user.');
END;
/

---3-create consumer group:
BEGIN
  DBMS_RESOURCE_MANAGER.create_consumer_group(
    consumer_group => 'TEST_USER_CG',
    comment        => 'Consumer group for TEST_USER');
END;
/


BEGIN
  DBMS_RESOURCE_MANAGER.SET_CONSUMER_GROUP_MAPPING(  
    ATTRIBUTE      => DBMS_RESOURCE_MANAGER.ORACLE_USER, 
    VALUE          => 'OE', 
    CONSUMER_GROUP => 'OLTP');
END;
/


---4:create Plan Directive ba mahdoodiyatha:cpu/active_Session/parallel
begin
DBMS_RESOURCE_MANAGER.create_plan_directive(
    plan                   => 'test_plan',
    group_or_subplan       => 'TEST_USER_CG',
    comment                => 'Limit all resources for TEST_USER',
    cpu_p1                 => 50,
    active_sess_pool_p1    => 3,
    parallel_degree_limit_p1 => 2);
end;
/

---4.1 :iops/

BEGIN
  DBMS_RESOURCE_MANAGER.UPDATE_CONSUMER_GROUP(
    consumer_group => 'TEST_USER_CG',
    max_iops       => 500,
    max_mbps       => 20,
    max_utilization_limit => 200);
END;
/








------
/**
 * mahdoodiyat cpu:
 */
EXEC DBMS_RESOURCE_MANAGER.CREATE_PLAN_DIRECTIVE(
  plan             => 'hybrid_plan',
  group_or_subplan => 'OLTP_GROUP',
  comment          => 'OLTP gets 60% CPU',
  cpu_p1           => 60);
---60 DARSAD CPU .

---
/**
 * mahdoodiyat active_Session
 */
 EXEC DBMS_RESOURCE_MANAGER.CREATE_PLAN_DIRECTIVE(
  plan                => 'hybrid_plan',
  group_or_subplan    => 'BATCH_GROUP',
  comment             => 'Limit batch active sessions to 5',
  active_sess_pool_p1 => 5);
  
 ---NAHAYT 5 ACTIVE_SESSION 
----
/**
 * mhdoodiyat temp usage:
 */
 
 EXEC DBMS_RESOURCE_MANAGER.CREATE_PLAN_DIRECTIVE(
  plan                => 'hybrid_plan',
  group_or_subplan    => 'BATCH_GROUP',
  comment             => 'Limit temp usage',
  max_utilization_limit => 500);

---500 MEGA BYTE.
---
/**
 * mahdoodiayt IO USAGE:
 */
 
 EXEC DBMS_RESOURCE_MANAGER.CREATE_PLAN_DIRECTIVE(
  plan             => 'hybrid_plan',
  group_or_subplan => 'BATCH_GROUP',
  comment          => 'Limit IOPS',
  max_iops         => 1000,
  max_mbps         => 50);
  
  ----HADAKSAR 1000 AMALIYAT IO dar saniye:
  ---ya 50 megabyte bar saniye.



---DAR NAHAYT BAYAD PALN VALIDATE VA SUBMIT BESHE.
BEGIN
  DBMS_RESOURCE_MANAGER.validate_pending_area;
  DBMS_RESOURCE_MANAGER.submit_pending_area;
END;
/
