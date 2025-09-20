--package test for pagination_new version:

DECLARE
    l_json   CLOB;
    l_result CLOB;
BEGIN
    -- ساخت JSON از جدول
    SELECT JSON_ARRAYAGG(JSON_OBJECT('id' VALUE id, 'name' VALUE name) RETURNING CLOB)
    INTO l_json
    FROM test_users;

    -- اجرای Pagination با پکیج جدید
    l_result := pagination_pkg_opt_4.get_paginated_data_from_clob(
        p_json_clob => l_json,
        p_path      => '/api/v1/test_users?offset=5' || chr(38) || 'limit=3'
    );

    DBMS_OUTPUT.put_line(l_result);
END;