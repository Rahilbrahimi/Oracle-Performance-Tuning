--Plan Instability
--zamani etefagh miyofte ke yek query moshabeh dar ejrahaye mokhtalef ba vojod sql_id sabet plan haye motafaveti migirad.
--query ke emrooz khoobe vali farda konde.
--avameli ke baes in mozo mishe chie ?
--1.peeked bindes:vaghti yek query baraye avalin bar ejra mishe oracle meghdar bind variable ra negah mikone va bar asas on executoon plan misaze.
--moshkel zamani etefagh miyofte ke ejraye badi ba meghdar motfavaeti az meghad bind miyad .(masalan meghdar selectivity paeen tar ya bozorghtar) vali optimizer hamoon plan ghabli ra estefade mikone.
--2:cursor sharing:Adaptive Cursor Sharing:momkene koli child cursor dashte bashim 
--chetor befamim:
--1.yek sql_id chandin child cursor dare
--2.yek query gahi tond ya gahi sari ejra mishe.
---baresi sql ba chand plan:
SELECT 
    sql_id,
    child_number,
    plan_hash_value,
    is_bind_sensitive,
    is_bind_aware,
    is_shareable
FROM 
    v$sql
WHERE 
    sql_id = 'sql_id_موردنظر';

---

SELECT 
    sql_id, 
    child_number, 
    reason 
FROM 
    v$sql_shared_cursor
WHERE 
    sql_id = 'sql_id_موردنظر';

-------------------------------

-----------baresi tedad plan haye motafavet baraye yek sql_id khas:
--chetor befhamim yek sql_id phan haye motafaveti dare :
SELECT 
    sql_id, 
    plan_hash_value, 
    COUNT(*) AS executions,
    MIN(first_load_time) AS first_seen,
    MAX(last_load_time) AS last_seen
FROM 
    v$sql
GROUP BY 
    sql_id, plan_hash_value
HAVING COUNT(*) > 1
ORDER BY executions DESC;

-----------------------
----------------baresi sql hae ke bish az yek child cursor daran va bind sensitive hastan:
SELECT 
    sql_id,
    COUNT(*) AS child_count,
    MAX(is_bind_sensitive) AS bind_sensitive,
    MAX(is_bind_aware) AS bind_aware
FROM 
    v$sql
GROUP BY sql_id
HAVING COUNT(*) > 1 AND MAX(is_bind_sensitive) = 'Y'
ORDER BY child_count DESC;

--------------------------------------------
----------shenase sql hae ke adaptive plan daran:

SELECT 
    sql_id,
    child_number,
    plan_hash_value,
    is_bind_sensitive,
    is_bind_aware,
    is_shareable,
    is_obsolete,
    last_active_time
FROM 
    v$sql
WHERE 
    sql_plan_baseline IS NULL 
    AND is_resolved_adaptive_plan = 'Y'
ORDER BY last_active_time DESC;

--------------------------------baresi sql hae ke bish az yek child cursor daran va bind sensitive hastan:
SELECT 
    sql_id,
    COUNT(*) AS child_count,
    MAX(is_bind_sensitive) AS bind_sensitive,
    MAX(is_bind_aware) AS bind_aware
FROM 
    v$sql
GROUP BY sql_id
HAVING COUNT(*) > 1 AND MAX(is_bind_sensitive) = 'Y'
ORDER BY child_count DESC;

------------------------moshahede bind peeking anjam shode baraye yek sql:
SELECT 
    sql_id,
    child_number,
    name,
    position,
    datatype_string,
    was_captured
FROM 
    v$sql_bind_capture
WHERE 
    sql_id = 'd4vjf44fb000c';
---------------------------------------------------
---------------

---------peyda kardan sql hae ke plan haye an be dalil bind taghir kardan.:
    SELECT 
    s.sql_id,
    s.plan_hash_value,
    s.child_number,
    ss.reason
FROM 
    v$sql s
JOIN 
    v$sql_shared_cursor ss 
ON 
    s.sql_id = ss.sql_id 
    AND s.child_number = ss.child_number
WHERE 
    ss.reason LIKE '%bind%';

-----------------------
SELECT * 
FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR('sql_id_موردنظر', child_number, 'ALLSTATS LAST +ADAPTIVE'));
