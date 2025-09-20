create or replace PACKAGE error_handling_pkg_3 AS
  FUNCTION generate_error_json(
    p_error_code IN VARCHAR2,
    p_path IN VARCHAR2 DEFAULT '/unknown/path'
  ) RETURN CLOB;

  PROCEDURE raise_error(
    p_error_code IN VARCHAR2
  );

<<<<<<< HEAD
    PROCEDURE RAISE_ERROR_V2(
        p_err_code IN VARCHAR2,
      
    );
	
	
	---generate kardan uuid v4 
	---handeling raise error 
	--dar nahayat baraye didan khoroji chap kardan dbms_output
	---


	-- Handles errors by building and outputting a JSON error response
	PROCEDURE handle (
		p_err_code         IN t_err_code DEFAULT NULL,
		p_err_name         IN t_err_name DEFAULT NULL,
		p_http_status_code OUT NOCOPY pkg_http.t_http_status_code
	) IS
		l_err_code t_err_code := NVL(p_err_code, SQLCODE);
		l_err_name t_err_name := NVL(p_err_name, SQLERRM);
		l_err_record t_err_record;
		
		
	procedure handle_errorr (
	
	p_err_code in t_err_Cdoe default null,
	p_err_name in t_err_name defualt null,
	p_http_status_code out pkg.t_hhtp_status_Code 
	
	)
	is 
	i_error_Code in t_err_Code defualt null,
	p_err_name in t_err_name default null,
	p_http_status
	
create or replace PACKAGE BODY ERROR_PKG AS
=======
  PROCEDURE handle_error(
    p_error_code IN VARCHAR2 DEFAULT NULL,
    p_path IN VARCHAR2 DEFAULT '/unknown/path',
    p_status_code OUT NUMBER
  );
END error_handling_pkg_3;

create or replace PACKAGE BODY error_handling_pkg_3 AS

--tarif record khata.
  TYPE t_err_record IS RECORD (
    status_code NUMBER,
    message VARCHAR2(4000),
    details VARCHAR2(4000)
  );
---gereftan data khata az table.inja az jadval mikhoonim age khata peyda shod khatara barmighrdoone age peyda nashod yek khataye pish farz 500 misazam.
  FUNCTION get_error(p_error_code IN VARCHAR2) RETURN t_err_record IS
    l_err_record t_err_record;
  BEGIN
    SELECT status_code, message, details
    INTO l_err_record
    FROM ERROR_DEFINITIONS
    WHERE code = p_error_code;
    RETURN l_err_record;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      l_err_record.status_code := 500;
      l_err_record.message := 'Error code not defined';
      l_err_record.details := 'Error code not found in definitions';
      RETURN l_err_record;
  END get_error;
--SAKHTE JSON 
  FUNCTION generate_error_json(
    p_error_code IN VARCHAR2,
    p_path IN VARCHAR2 DEFAULT '/unknown/path'
  ) RETURN CLOB IS
    l_json_obj JSON_OBJECT_T := NEW JSON_OBJECT_T();
    l_error_obj JSON_OBJECT_T := NEW JSON_OBJECT_T();
    l_uuid VARCHAR2(36) := LOWER(RAWTOHEX(SYS_GUID()));
    l_err_record t_err_record := get_error(NVL(p_error_code, 'UNKNOWN_ERROR'));
  BEGIN
    l_json_obj.put('status', 'error');
    l_json_obj.put('statusCode', l_err_record.status_code);
    l_error_obj.put('code', NVL(p_error_code, 'UNKNOWN_ERROR'));
    l_error_obj.put('message', l_err_record.message);
    l_error_obj.put('details', l_err_record.details);
    l_error_obj.put('timestamp', TO_CHAR(SYSTIMESTAMP, 'YYYY-MM-DD"T"HH24:MI:SS"Z"')); --
    l_error_obj.put('path', p_path);
    l_json_obj.put('error', l_error_obj);
    l_json_obj.put('requestId',
      SUBSTR(l_uuid, 1, 8) || '-' || SUBSTR(l_uuid, 9, 4) || '-' ||
      SUBSTR(l_uuid, 13, 4) || '-' || SUBSTR(l_uuid, 17, 4) || '-' || SUBSTR(l_uuid, 21));

---baraye inke betoonim dar zaman mahali estefade beshe va local bashe mitoonim az TO_CHAR(SYS_EXTRACT_UTC(SYSTIMESTAMP), 'YYYY-MM-DD"T"HH24:MI:SS"Z"') estefade konim.


    RETURN l_json_obj.to_clob();
  END generate_error_json;
---FERESTADAN KHATA
  PROCEDURE raise_error(
    p_error_code IN VARCHAR2
) IS
    l_err_record t_err_record := get_error(NVL(p_error_code, 'UNKNOWN_ERROR'));
BEGIN
    RAISE_APPLICATION_ERROR(-20000,
        NVL(p_error_code, 'UNKNOWN_ERROR') || ': ' || l_err_record.message); -- فقط کد و پیام
END raise_error;

PROCEDURE handle_error(
    p_error_code IN VARCHAR2 DEFAULT NULL,
    p_path IN VARCHAR2 DEFAULT '/unknown/path',
    p_status_code OUT NUMBER
) IS
    l_err_code VARCHAR2(4000); -- ظرفیت افزایش یافته
    l_sql_errm VARCHAR2(4000);
BEGIN
    l_sql_errm := SUBSTR(NVL(SQLERRM, 'System error'), 1, 4000);
    l_err_code := NVL(p_error_code, TO_CHAR(SQLCODE));
>>>>>>> 2208d59dd51246d4039a834f1ef5c66757f45b8d

    IF p_error_code IS NULL THEN
        l_err_code := REGEXP_REPLACE(l_sql_errm, '^ORA-\d+: ', '');
    END IF;

<<<<<<< HEAD
        -- گرفتن یک requestId از جدول REQUEST_ID_POOL
        SELECT ID 
        INTO l_request_id
        FROM REQUEST_ID_SEQ
        WHERE ROWNUM = 1;

  

        -- ساخت JSON استاندارد
        l_err_json_obj := NEW JSON_OBJECT_T();
        l_err_json_obj.put('status', 'error');
        l_err_json_obj.put('statusCode', NVL(l_err_record.STATUS_CODE, 500));

        l_error_obj := NEW JSON_OBJECT_T();
        l_error_obj.put('code', NVL(l_err_record.CODE,'UNKNOWN_ERROR'));
        l_error_obj.put('message', NVL(l_err_record.MESSAGE,'Unknown error'));
        l_error_obj.put('details', NVL(l_err_record.DETAILS,''));
        l_error_obj.put('timestamp', TO_CHAR(SYSTIMESTAMP, 'YYYY-MM-DD"T"HH24:MI:SS"Z"'));
        l_error_obj.put('path', l_http_uri_path);

        l_err_json_obj.put('error', l_error_obj);

      

        -- تبدیل JSON به CLOB
        l_err_json_clob := l_err_json_obj.to_clob();

        -- ارسال JSON به کلاینت
        owa_util.mime_header('application/json', TRUE);
        htp.p(l_err_json_clob);

        -- قطع اجرای برنامه با خطای PL/SQL
        RAISE_APPLICATION_ERROR(-20000, l_err_json_clob);

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            -- JSON خطای ناشناخته
            l_err_json_obj := NEW JSON_OBJECT_T();
            l_err_json_obj.put('status','error');
            l_err_json_obj.put('statusCode',500);

            l_error_obj := NEW JSON_OBJECT_T();
            l_error_obj.put('code','UNKNOWN_ERROR');
            l_error_obj.put('message','Unknown error code');
            l_error_obj.put('details','');
            l_error_obj.put('timestamp', TO_CHAR(SYSTIMESTAMP, 'YYYY-MM-DD"T"HH24:MI:SS"Z"'));
            l_error_obj.put('path', NVL(p_uri,'/unknown/path'));

            l_err_json_obj.put('error', l_error_obj);

         
            BEGIN
                SELECT ID INTO l_request_id FROM REQUEST_ID_SEQ WHERE ROWNUM = 1;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    l_request_id := 'REQ-UNKNOWN';
            END;

            l_err_json_obj.put('requestId', l_request_id);

            l_err_json_clob := l_err_json_obj.to_clob();

            owa_util.mime_header('application/json', TRUE);
            htp.p(l_err_json_clob);

            RAISE_APPLICATION_ERROR(-20099, 'Unknown error code');
    END RAISE_ERROR_V2;

END ERROR_PKG;
=======
    p_status_code := get_error(l_err_code).status_code;
    -- فقط پیام خطا لاگ می‌شه
    ---DBMS_OUTPUT.PUT_LINE('Error: ' || l_err_code || ' at ' || p_path);
END handle_error;
END error_handling_pkg_3;
>>>>>>> 2208d59dd51246d4039a834f1ef5c66757f45b8d
