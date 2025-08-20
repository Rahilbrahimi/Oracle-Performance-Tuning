---CODE ERROR HANDELING 3:

create or replace NONEDITIONABLE PACKAGE ERROR_PKG AS

    PROCEDURE RAISE_ERROR_V2(
        p_err_code IN VARCHAR2,
        p_uri      IN VARCHAR2 DEFAULT NULL
    );


END ERROR_PKG;

create or replace PACKAGE BODY ERROR_PKG AS

    PROCEDURE RAISE_ERROR_V2(
        p_err_code IN VARCHAR2,
        p_uri      IN VARCHAR2 DEFAULT NULL
    ) IS
        l_err_record      API_ERROR_HTTP%ROWTYPE;
        l_err_json_obj    JSON_OBJECT_T;
        l_error_obj       JSON_OBJECT_T;
        l_err_json_clob   CLOB;
        l_http_uri_path   VARCHAR2(4000);
        l_request_id      VARCHAR2(50);
    BEGIN
        -- گرفتن اطلاعات خطا از جدول
        SELECT *
        INTO l_err_record
        FROM API_ERROR_HTTP
        WHERE CODE = p_err_code;

        SELECT ID 
        INTO l_request_id
        FROM REQUEST_ID_SEQ
        WHERE ROWNUM = 1;

        -- تعیین مسیر URI
        IF p_uri IS NOT NULL THEN
            l_http_uri_path := p_uri;
        ELSE
            l_http_uri_path := SUBSTR(OWA_UTIL.GET_CGI_ENV('/api/v1/users/12345'), 1, 4000);
            IF l_http_uri_path IS NULL THEN
                l_http_uri_path := '/unknown/path';
            END IF;
        END IF;

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

        -- استفاده از requestId از جدول
        l_err_json_obj.put('requestId', l_request_id);

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
