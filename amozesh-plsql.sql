---amoozesh plsql:

--1:avalin estefade az sysdate :
_today date:=sysdate;
begin 
dbms_output.put_line ('today is ;'||to_Char(i_today,'day'));
end ;
/

--2:
declare 
i_today date:= sysdate ;

begin 
if to_char( i_today,'d') < 4 then
dbms_output.put_line ('today is <4 pas kar kon, ') ;
elsif 
to_Char(i_today,'d') =  6 then
dbms_output.put_line ('today is jome,tatil rasmi asat');
else
dbms_output.put_line ('alan akahr haftas keyf kon');
end if ;
dbms_output.put_line ('today is '|| to_Char(i_today,'day') || ' DAY ' || to_Char(i_today,'day') || 'of the week');
end;

---fargh paeeni ba balae chie:
DECLARE
    l_today DATE := SYSDATE;
    l_day_num NUMBER;
BEGIN
    l_day_num := TO_NUMBER(TO_CHAR(l_today, 'D'));

    IF l_day_num = 6 THEN
        DBMS_OUTPUT.PUT_LINE('امروز جمعه است، تعطیل رسمی!');
    ELSE
        DBMS_OUTPUT.PUT_LINE('امروز روز کاری است.');
    END IF;

    DBMS_OUTPUT.PUT_LINE('امروز ' || TO_CHAR(l_today, 'Day') || ' است.');
END;
/
---dg lazem nis ke bad az har else ya elsif az to_Char estefade koni.


--static sql:
DECLARE
  howmany     INTEGER;
  num_tables  INTEGER;
BEGIN
  -- Begin processing
  SELECT COUNT(*) INTO howmany
  FROM USER_OBJECTS
  WHERE OBJECT_TYPE = 'INDEX'; -- Check number of tables
  num_tables := howmany;       -- Compute another value
  dbms_output.put_line (to_char(num_tables,'999G999G999')||' tables');
END;

----fromat '999g999g999 yani 3 ragham 3 ragham adad ra joda kon.
--TO_CHAR(number, format_model).
---tafavot integer va number inke number mitoone adad sahih nabashe va adad ashari bashe vali integer hamishe adad sahih va age kasi bebine code ra motovajeh mishe ghara nis chiz dg bargarde.
--cursor for loop:
--dar sql vaghti yek select mizani momkene chand radif behet bragrdoone ama dar pl mitoonim az plsql estefade konim ke row be row pardazesh kone.
--cursor for loop:baraye har satr az khoroji select yek bar block ejra mishe.
--bedoon inke dasti cursor baz va baste beshe.
--sakhtar koli:
BEGIN
  FOR record_variable IN (SELECT ... FROM ...) LOOP
    -- کدهایی که برای هر ردیف اجرا می‌شن
  END LOOP;
END;
/

--alave bar peymayesh jadavel baraye har jadval tedad rows ra ham beshmorad.va faghat jadavel ke bish az 10 radif daran.ra namayesh midahad.

---nemoone cursor for loop:
DECLARE
  l_count      INTEGER := 0;
BEGIN
  FOR tbl IN (
    SELECT table_name
    FROM user_tables
    ORDER BY table_name
  ) LOOP
    DECLARE
      l_rows INTEGER;
    BEGIN
      EXECUTE IMMEDIATE 
        'SELECT COUNT(*) FROM ' || tbl.table_name
        INTO l_rows;

      IF l_rows > 10 THEN
        l_count := l_count + 1;
        dbms_output.put_line(tbl.table_name || ' => ' || l_rows || ' rows');
      END IF;

    EXCEPTION
      WHEN OTHERS THEN
        dbms_output.put_line('Error checking ' || tbl.table_name);
    END;
  END LOOP;

  IF l_count = 0 THEN
    dbms_output.put_line('No tables with more than 10 rows found.');
  END IF;
END;
----baresi tedad radif haye har view dar user_views va chap anhae ke bishtar az 100 radif daran:
---dar halat cursor for looop niyazi nis ma cursor ra tarif konim dar bakhsh declare
---balke mostaghim dar bakhsh for yek select minevisim va khode oracle cursor ra baz mikone va fetch mikone.va khodesh ham mibande.
--mesal:Explicit Cursor :dar in ravesh ebteda bayad cursor ra dar bakhsh declare tarif koni zamani mofid ke bekhay contorol bishtari dashte bashi.
--bekhay ghabl az baz kardan shart hae ra baresi koni.bekhay chand bar azash meghdar begiri.
--bekhay dastoorat pichide ba parameter haye vorodi dashte bashi.
--mesal:
DECLARE
  CURSOR emp_cur IS
    SELECT employee_id, salary FROM employees WHERE department_id = 10;
  
  emp_rec emp_cur%ROWTYPE;
BEGIN
  OPEN emp_cur;
  LOOP
    FETCH emp_cur INTO emp_rec;
    EXIT WHEN emp_cur%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE('Emp ID: ' || emp_rec.employee_id || ' Salary: ' || emp_rec.salary);
  END LOOP;
  CLOSE emp_cur;
END;
---key az expilicit cursor estefade mikonim?
--vaghti lazem bashe bad az har bar fetch amaliyati roosh anjam beshe.
--age bekhay ba darsad pishraft ba rowcount% ya found% estefade koni.
---%ROWCOUNT:Zamani ke mikhahim bedanim chand record tahte tasir ghara gereftan.tedad record haye pardazesh shode.
--%found:age faghat bekhay bedooni record taghir karde ya na .
--%found :boolean hast va az jense TRUE va False hast.
--vizhegi %notfound:vaghti hich radif peyda nashe true barmigardooone.

---mesal:
DELETE FROM users
WHERE user_id = 100;

IF SQL%FOUND THEN
   DBMS_OUTPUT.PUT_LINE('کاربر حذف شد.');
ELSE
   DBMS_OUTPUT.PUT_LINE('کاربری با این ID پیدا نشد.');
END IF;
----bad az amaliyat insert,update,delete az halat bala mishe estefade kard.:
---%rowcount:in vizehgi baraye zamani asat ke bekhay bedooni chand radif taghir karde ya entekhab shode.
---bad az amaliyat update,delete,insert
INSERT INTO log_table (msg)
VALUES ('Test log entry');
DBMS_OUTPUT.PUT_LINE('تعداد رکوردهای درج شده: ' || SQL%ROWCOUNT);
---
UPDATE orders
SET status = 'shipped'
WHERE customer_id = 200;

DBMS_OUTPUT.PUT_LINE('تعداد سفارش‌های به‌روزرسانی شده: ' || SQL%ROWCOUNT);
-------------
--dar cursor baraye shomaresh recordhaye fetch shode.




--cursor for loop:

BEGIN
  FOR emp_rec IN (SELECT employee_id, salary FROM employees WHERE department_id = 10)
  LOOP
    DBMS_OUTPUT.PUT_LINE('Emp ID: ' || emp_rec.employee_id || ' Salary: ' || emp_rec.salary);
  END LOOP;
END;
-------------------
---halat dovom:
SET SERVEROUTPUT ON;

DECLARE
    CURSOR view_cursor IS
        SELECT view_name FROM user_views;
        
    v_sql   VARCHAR2(1000);
    v_count NUMBER;
BEGIN
    FOR view_rec IN view_cursor LOOP
        BEGIN
            v_sql := 'SELECT COUNT(*) FROM ' || view_rec.view_name;
            EXECUTE IMMEDIATE v_sql INTO v_count;

            IF v_count > 100 THEN
                DBMS_OUTPUT.PUT_LINE(view_rec.view_name || ' has ' || v_count || ' rows.');
            END IF;
        EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('Error querying view: ' || view_rec.view_name || ' - ' || SQLERRM);
        END;
    END LOOP;
END;
---soal dar rabete ba tamrin bala che zaman hae ma az halat bala cursor ra minevisim?
--baresi table hae ke bish az 3 index daran:
SET SERVEROUTPUT ON;

DECLARE
    CURSOR tbl_cur IS
        SELECT table_name FROM user_tables;

    v_count  NUMBER;
    v_found  BOOLEAN := FALSE;
BEGIN
    FOR t_rec IN tbl_cur LOOP
        SELECT COUNT(*)
        INTO v_count
        FROM user_indexes
        WHERE table_name = t_rec.table_name;

        IF v_count > 3 THEN
            DBMS_OUTPUT.PUT_LINE(t_rec.table_name || ' has ' || v_count || ' indexes.');
            v_found := TRUE;
        END IF;
    END LOOP;

    IF NOT v_found THEN
        DBMS_OUTPUT.PUT_LINE('No tables found with more than 3 indexes.');
    END IF;
END;


declare 

