CREATE OR REPLACE PACKAGE pagination_pkg_opt AS
  FUNCTION get_paginated_data(
    p_table_name IN VARCHAR2,
    p_offset IN NUMBER DEFAULT 0,
    p_limit IN NUMBER DEFAULT 100,
    p_path IN VARCHAR2 DEFAULT '/api/v1/data'
  ) RETURN CLOB;
END pagination_pkg_opt;
/

CREATE OR REPLACE PACKAGE BODY pagination_pkg_opt AS

  c_max_limit CONSTANT NUMBER := 1000;

  FUNCTION is_table_allowed(p_table_name VARCHAR2) RETURN BOOLEAN IS
  BEGIN
    RETURN p_table_name IN ('TABLE1','TABLE2','TABLE3'); 
  END;

  FUNCTION build_link(p_path IN VARCHAR2, p_offset IN NUMBER, p_limit IN NUMBER) RETURN VARCHAR2 IS
    l_link VARCHAR2(4000) := p_path;
    l_first BOOLEAN := TRUE;
  BEGIN
    IF p_offset IS NOT NULL AND p_offset >= 0 THEN
      IF l_first THEN
        l_link := l_link ||  CHR(63) || 'offset=' || p_offset;
        l_first := FALSE;
      ELSE
        l_link := l_link || CHR(38) || 'offset=' || p_offset;
      END IF;
    END IF;

    IF p_limit IS NOT NULL AND p_limit > 0 THEN
      IF l_first THEN
        l_link := l_link || CHR(63) || 'limit=' || p_limit;
      ELSE
        l_link := l_link || CHR(38) || 'limit=' || p_limit;
      END IF;
    END IF;

    RETURN l_link;
  END build_link;

  FUNCTION get_self_link(p_path IN VARCHAR2, p_offset IN NUMBER, p_limit IN NUMBER) RETURN VARCHAR2 IS
  BEGIN
    RETURN build_link(p_path, p_offset, p_limit);
  END;

  FUNCTION get_first_link(p_path IN VARCHAR2, p_limit IN NUMBER) RETURN VARCHAR2 IS
  BEGIN
    RETURN build_link(p_path, 0, p_limit);
  END;

  FUNCTION get_next_link(p_path IN VARCHAR2, p_offset IN NUMBER, p_limit IN NUMBER, p_count IN NUMBER) RETURN VARCHAR2 IS
  BEGIN
    IF p_count = p_limit THEN
      RETURN build_link(p_path, p_offset + p_limit, p_limit);
    ELSE
      RETURN NULL;
    END IF;
  END;

  FUNCTION get_prev_link(p_path IN VARCHAR2, p_offset IN NUMBER, p_limit IN NUMBER) RETURN VARCHAR2 IS
  BEGIN
    IF p_offset > 0 THEN
      RETURN build_link(p_path, GREATEST(p_offset - p_limit, 0), p_limit);
    ELSE
      RETURN NULL;
    END IF;
  END;

  FUNCTION get_paginated_data(
    p_table_name IN VARCHAR2,
    p_offset IN NUMBER DEFAULT 0,
    p_limit IN NUMBER DEFAULT 100,
    p_path IN VARCHAR2 DEFAULT '/api/v1/data'
  ) RETURN CLOB IS
    l_json_obj JSON_OBJECT_T := NEW JSON_OBJECT_T();
    l_data_array JSON_ARRAY_T := NEW JSON_ARRAY_T();
    l_pagination_obj JSON_OBJECT_T := NEW JSON_OBJECT_T();
    l_links_array JSON_ARRAY_T := NEW JSON_ARRAY_T();
    l_count NUMBER := 0;
    l_query VARCHAR2(4000);
    l_cursor SYS_REFCURSOR;
    l_json_row CLOB;
    l_status_code NUMBER;
  BEGIN

    IF NOT is_table_allowed(p_table_name) THEN
      error_handling_pkg_3.handle_error('INVALID_TABLE', p_path, l_status_code);
      RETURN NULL;
    END IF;


    IF p_offset < 0 OR p_limit < 1 OR p_limit > c_max_limit THEN
      error_handling_pkg_3.handle_error('INVALID_PAGINATION', p_path, l_status_code);
      RETURN NULL;
    END IF;

    l_query := 'SELECT JSON_ARRAYAGG(JSON_OBJECT(*)) FROM (' ||
               'SELECT * FROM ' || p_table_name || ' ORDER BY ID OFFSET :1 ROWS FETCH NEXT :2 ROWS ONLY' ||
               ')';

    OPEN l_cursor FOR l_query USING p_offset, p_limit;
    FETCH l_cursor INTO l_json_row;
    CLOSE l_cursor;

    l_data_array := JSON_ARRAY_T.parse(NVL(l_json_row, '[]'));
    l_count := l_data_array.get_size;

    DECLARE l_link_obj JSON_OBJECT_T; BEGIN

      l_link_obj := NEW JSON_OBJECT_T();
      l_link_obj.put('rel','self');
      l_link_obj.put('href', get_self_link(p_path, p_offset, p_limit));
      l_links_array.append(l_link_obj);

      l_link_obj := NEW JSON_OBJECT_T();
      l_link_obj.put('rel','first');
      l_link_obj.put('href', get_first_link(p_path, p_limit));
      l_links_array.append(l_link_obj);


      IF p_offset > 0 THEN
        l_link_obj := NEW JSON_OBJECT_T();
        l_link_obj.put('rel','previous');
        l_link_obj.put('href', get_prev_link(p_path, p_offset, p_limit));
        l_links_array.append(l_link_obj);
      END IF;

      -- next
      IF l_count = p_limit THEN
        l_link_obj := NEW JSON_OBJECT_T();
        l_link_obj.put('rel','next');
        l_link_obj.put('href', get_next_link(p_path, p_offset, p_limit, l_count));
        l_links_array.append(l_link_obj);
      END IF;
    END;


    l_json_obj.put('status','success');
    l_json_obj.put('data', l_data_array);
    l_pagination_obj.put('limit', p_limit);
    l_pagination_obj.put('offset', p_offset);
    l_pagination_obj.put('count', l_count);
    l_pagination_obj.put('hasMore', l_count = p_limit);
    l_pagination_obj.put('links', l_links_array);
    l_json_obj.put('pagination', l_pagination_obj);

    RETURN l_json_obj.to_clob();

  EXCEPTION
    WHEN OTHERS THEN
      error_handling_pkg_3.handle_error(NULL, p_path, l_status_code);
      RETURN NULL;
  END get_paginated_data;

END pagination_pkg_opt;

--------------------
--baraye checking:

DECLARE
  P_TABLE_NAME VARCHAR2(200);
  P_OFFSET NUMBER;
  P_LIMIT NUMBER;
  P_PATH VARCHAR2(200);
  v_Return CLOB;
BEGIN
  P_TABLE_NAME := 'TABLE1';
  P_OFFSET := 0;
  P_LIMIT := 2;
  P_PATH := '/api/v1/table1';

  v_Return := PAGINATION_PKG_OPT.GET_PAGINATED_DATA(
    P_TABLE_NAME => P_TABLE_NAME,
    P_OFFSET => P_OFFSET,
    P_LIMIT => P_LIMIT,
    P_PATH => P_PATH
  );
 
DBMS_OUTPUT.PUT_LINE('v_Return = ' || v_Return);

-- :v_Return := v_Return;
--rollback; 
END;


DECLARE
  P_TABLE_NAME VARCHAR2(200);
  P_OFFSET NUMBER;
  P_LIMIT NUMBER;
  P_PATH VARCHAR2(200);
  v_Return CLOB;
BEGIN
  P_TABLE_NAME := 'TABLE1';
  P_OFFSET := 2;
  P_LIMIT := 2;
  P_PATH := '/api/v1/table1';

  v_Return := PAGINATION_PKG_OPT.GET_PAGINATED_DATA(
    P_TABLE_NAME => P_TABLE_NAME,
    P_OFFSET => P_OFFSET,
    P_LIMIT => P_LIMIT,
    P_PATH => P_PATH
  );
 
DBMS_OUTPUT.PUT_LINE('v_Return = ' || v_Return);

-- :v_Return := v_Return;
--rollback; 
END;
----------------------------------
DECLARE
  P_TABLE_NAME VARCHAR2(200);
  P_OFFSET NUMBER;
  P_LIMIT NUMBER;
  P_PATH VARCHAR2(200);
  v_Return CLOB;
BEGIN
  P_TABLE_NAME := 'TABLE1';
  P_OFFSET := 4;
  P_LIMIT := 2;
  P_PATH := '/api/v1/table1';

  v_Return := PAGINATION_PKG_OPT.GET_PAGINATED_DATA(
    P_TABLE_NAME => P_TABLE_NAME,
    P_OFFSET => P_OFFSET,
    P_LIMIT => P_LIMIT,
    P_PATH => P_PATH
  );
 
DBMS_OUTPUT.PUT_LINE('v_Return = ' || v_Return);

-- :v_Return := v_Return;
--rollback; 
END;

