create or replace PACKAGE error_handling_pkg_3 AS
  FUNCTION generate_error_json(
    p_error_code IN VARCHAR2,
    p_path IN VARCHAR2 DEFAULT '/unknown/path'
  ) RETURN CLOB;

  PROCEDURE raise_error(
    p_error_code IN VARCHAR2
  );

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
      'Status: ' || l_err_record.status_code || ', ' ||
      NVL(p_error_code, 'UNKNOWN_ERROR') || ': ' || l_err_record.message || ' - ' || l_err_record.details);
  END raise_error;

  PROCEDURE handle_error(
    p_error_code IN VARCHAR2 DEFAULT NULL,
    p_path IN VARCHAR2 DEFAULT '/unknown/path',
    p_status_code OUT NUMBER
  ) IS
    l_err_code VARCHAR2(50);
  BEGIN
    
    l_err_code := NVL(p_error_code, TO_CHAR(SQLCODE));

    
    IF p_error_code IS NULL THEN
        l_err_code := REGEXP_REPLACE(NVL(SQLERRM, 'System error'), '^ORA-\d+: ', '');
    END IF;

    p_status_code := get_error(l_err_code).status_code;

  
    DBMS_OUTPUT.PUT_LINE(generate_error_json(l_err_code, p_path));
  END handle_error;
END error_handling_pkg_3;
