<<<<<<< HEAD
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

=======
/*********************************************************************
 * PACKAGE: pagination_pkg_opt_3
 *
 * This package provides utilities for paginating JSON data stored as CLOB.
 * It supports extracting offset and limit from SQL queries, validating inputs,
 * slicing JSON arrays, building pagination links, and generating paginated JSON responses.
 *********************************************************************/

/**
  * get_offset_limit_from_query
  *
  * Extracts OFFSET and FETCH NEXT (limit) values from a SQL query string.
  *
  * @param p_sql_query       SQL query containing OFFSET and FETCH NEXT clauses
  * @param p_offset          OUT parameter to hold extracted OFFSET value
  * @param p_limit           OUT parameter to hold extracted FETCH NEXT value
  * @param p_default_offset  Default offset if not found in the query (default 0)
  * @param p_default_limit   Default limit if not found in the query (default 100)
 */
create or replace PACKAGE pagination_pkg_opt AS
procedure get_offset_limit_from_query(
  p_sql_query in varchar2,
  p_offset out number,
  p_limit out number,
  p_default_offset in number default 0,
  p_default_limit in number default 100);
/**
 *Validate_offset
 *Validate the provided offset value.
 *
 *@param p_offset offset to validate
 *
 *@raises PAGINATION_OFFSET_ERR if offset is negative
 */
procedure validate_offset(p_offset in number);
/**
 *
 *Validates the provide limit value.
 *
 *@param p_limit Limit to validate
 *
 *@raises PAGINATION_LIMIT_ERR if limit is less than 1
 */
procedure validate_limit(p_limit in number);
/**
 *update_url_with_pagination
 *
 *update an API URL with the provide offset and limit values,only if they exist in the URL.
 *
 *@param p_url Original URL
 *@param p_offset offset value to insert/update
 *@param p_limit Limit value to insert/update
 *
 *@return Update URL with new offset and limit 
 */
function update_url_with_pagination(
  p_url in varchar2,
  p_offset in number,
  p_limit in number )
  return varchar2;
/**
 *count_items
 *
 *counts the number of elements in JSON_ARRAY_T object.
 *
 *@param p_Data JSON array to count
 *
 *@return Number of items in the array
 */
function count_items(p_data JSON_ARRAY_T) RETURN NUMBER;
/**
 *has_next_page
 *
 *Determines if there is a next page based on currenct offset,limit,and total items.
 *
 *@param p_offset Current offset
 *@param p_limit Currenct limit
 *@param p_total Total number of  items
 *
 *@return TRUE if next page exists,FALSE otherwise
 */
FUNCTION has_next_page(p_offset IN NUMBER, p_limit IN NUMBER, p_total IN NUMBER) RETURN BOOLEAN;
/**
 *remove_last_element
 *
 *Remove the last element from JSON_ARRAY_T object.
 *@param p_Data JSON array to modify(IN OUT)
 */
PROCEDURE remove_last_element(p_data IN OUT NOCOPY JSON_ARRAY_T);
/**
 *build_pagination_links
 *
 *Generates an array of pagination link objects(self,first,previous,next,last)for a given path.
 *
 *@param p_path API path to build links
 *@param p_offset Currenct offset
 *@param p_limit Currenct limit
 *@param p_total Total number of items
 *
 *@return JSON_ARRAY_T containing pagination link objects
 */
FUNCTION build_pagination_links(
    p_path   IN VARCHAR2,
    p_offset IN NUMBER,
    p_limit  IN NUMBER,
    p_total  IN NUMBER
) RETURN JSON_ARRAY_T;
/**
 * get_paginated_data_from_clob
 *
 * Main function to paginate a JSON array stored as CLOB.
 * Produces a JSON object with paginated data, pagination info, and navigation links.
 *
 * @param p_json_clob  CLOB containing JSON array (required)
 * @param p_offset     Starting offset for pagination (default 0)
 * @param p_limit      Number of items per page (default 100)
 * @param p_path       API path used to generate pagination links (default '/api/v1/data')
 *
 * @return CLOB containing paginated JSON object, which includes:
 *         - status: success or error
 *         - data: array of records for current page
 *         - pagination: object containing limit, offset, count, hasMore, total, links
 *
 * @raises PAGINATION_NULL          if p_json_clob is NULL
 * @raises PAGINATION_INVALID_JSON  if p_json_clob is not valid JSON
 * @raises PAGINATION_NO_ARRAY      if JSON array is empty
 * @raises PAGINATION_OFFSET_ERR    if offset is negative
 * @raises PAGINATION_LIMIT_ERR     if limit is less than 1
 */
FUNCTION get_paginated_data_from_clob(
    p_json_clob IN CLOB,
    p_offset    IN NUMBER DEFAULT 0,
    p_limit     IN NUMBER DEFAULT 100,
    p_path      IN VARCHAR2 DEFAULT '/api/v1/data'
) RETURN CLOB;


create or replace PACKAGE BODY pagination_pkg_opt AS
-------------------------------------------------------------------------------
 /**
  *Extract offset and limit from sql query
  */
 --------------------------------------------------
 procedure get_offset_limit_from_query(
   p_Sql_query IN VARCHAR2,
   p_offset OUT NUMBER,
   p_limit OUT NUMBER,
   P_DEFAULT_OFFSET IN NUMBER DEFAULT 0,
   p_default_limit IN number DEFAULT 100
 ) IS 
 BEGIN 
   p_offset := NVL(
      TO_NUMBER(
           REGEXP_SUBSTR(p_sql_query,'OFFSET\s+(\d+)\s+ROWS',1,1,NULL,1)
      ),
      p_default_offset 
 );
  p_limit := NVL(TO_NUMBER(REGEX_SUBSTR(p_sql_query,'FETCH\s+NEXT\s+(\d+)\s+ROWS\s+ONLY',1, 1, NULL, 1)
   ),
   p_default_limit

  );
END get_offset_limit_from_query;

-------------------------------------------------------------------------------------
/**
 *VALIDATION 
 */
-------------------------------------------------------------------------------------
 PROCEDURE validate_offset(p_offset IN NUMBER) IS
  BEGIN
      IF p_offset < 0 THEN
          error_handling_pkg_3.raise_error('PAGINATION_OFFSET_ERR');
      END IF;
  END validate_offset;

  PROCEDURE validate_limit(p_limit IN NUMBER) IS
  BEGIN
      IF p_limit < 1 THEN
          error_handling_pkg_3.raise_error('PAGINATION_LIMIT_ERR');
      END IF;
  END validate_limit;
------------------------------------------------------------------------------
/**
 *Update URL if offset/limit exists
 */
------------------------------------------------------------------------
 FUNCTION update_url_with_pagination(
    p_url    IN VARCHAR2,
    p_offset IN NUMBER,
    p_limit  IN NUMBER
) RETURN VARCHAR2 IS
    l_url VARCHAR2(4000) := p_url;
BEGIN
 IF REGEXP_INSTR(l_url, '([?&]offset=)') > 0 THEN
        l_url := REGEXP_REPLACE(l_url, '([?&]offset=)([^&]*)', '\1' || p_offset);
    END IF;
 IF REGEXP_INSTR(l_url, '([?&]limit=)') > 0 THEN
        l_url := REGEXP_REPLACE(l_url, '([?&]limit=)([^&]*)', '\1' || p_limit);
    END IF;
  RETURN l_url;
END update_url_with_pagination;
------------------------------------------------------------------------
/**
 *Count and next page
 */
------------------------------------------------------------------
FUNCTION count_items(p_data JSON_ARRAY_T) RETURN NUMBER IS
  BEGIN
      RETURN p_data.get_size;
  END count_items;

  FUNCTION has_next_page(p_offset IN NUMBER, p_limit IN NUMBER, p_total IN NUMBER) RETURN BOOLEAN IS
  BEGIN
      RETURN (p_offset + p_limit) < p_total;
  END has_next_page;
---------------------------------------------------------------------------------
/**
 *remove last element
 */
------------------------------------------------------------------------------
procedure remove_last_element(p_data IN OUT NOCOPY JSON_ARRAY_T) IS 
BEGIN 
   IF p_data.get_size >0 then 
     p_data.remove(p_data.get_Size-1);
  end id;
end remove_last_element;
------------------------------------------------------------------------
/**
 * build function links
 */
----------------------------------------------------------
function build_pagination_links(
  p_path in varchar2,
  p_offset in number,
  p_limit in number,
  p_total in number 
)return JSON_ARRAY_T is 
 i_link_array JSON_ARRAY_T := NEW JSON_ARRAY_T();
 i_link_obj JSON_OBJECT_T;
BEGIN 
 ---self
 l_link_obj := NEW JSON_OBJECT_T();
      l_link_obj.put('rel','self');
      l_link_obj.put('href', update_url_with_pagination(p_path, p_offset, p_limit));
      l_links_array.append(l_link_obj);
 -- first
      l_link_obj := NEW JSON_OBJECT_T();
      l_link_obj.put('rel','first');
      l_link_obj.put('href', update_url_with_pagination(p_path, 0, p_limit));
      l_links_array.append(l_link_obj);

      -- prev
      IF p_offset > 0 THEN
          l_link_obj := NEW JSON_OBJECT_T();
          l_link_obj.put('rel','previous');
          l_link_obj.put('href', update_url_with_pagination(p_path, GREATEST(p_offset - p_limit, 0), p_limit));
          l_links_array.append(l_link_obj);
      END IF;

      -- next
      IF has_next_page(p_offset, p_limit, p_total) THEN
          l_link_obj := NEW JSON_OBJECT_T();
          l_link_obj.put('rel','next');
          l_link_obj.put('href', update_url_with_pagination(p_path, p_offset + p_limit, p_limit));
          l_links_array.append(l_link_obj);
      END IF;

      -- last
      IF p_total > p_limit THEN
          l_link_obj := NEW JSON_OBJECT_T();
          l_link_obj.put('rel','last');
          l_link_obj.put('href', update_url_with_pagination(
              p_path,
              (TRUNC((p_total - 1) / p_limit) * p_limit),
              p_limit
          ));
          l_links_array.append(l_link_obj);
      END IF;

      RETURN l_links_array;
  END build_pagination_links;

 

 ----------------------------------------------------
/**
 * main function 
 */
------------------------------------------------
  FUNCTION get_paginated_data_from_clob(
      p_json_clob IN CLOB,
      p_offset    IN NUMBER DEFAULT 0,
      p_limit     IN NUMBER DEFAULT 100,
      p_path      IN VARCHAR2 DEFAULT '/api/v1/data'
  ) RETURN CLOB IS
       l_json_obj       JSON_OBJECT_T := NEW JSON_OBJECT_T();
      l_data_array     JSON_ARRAY_T;
      l_slice_array    JSON_ARRAY_T := NEW JSON_ARRAY_T();
      l_pagination_obj JSON_OBJECT_T := NEW JSON_OBJECT_T();
      l_total_count    NUMBER;
      l_end_index      NUMBER;
      l_status_code    NUMBER;
  BEGIN
     ------------------------------------------------------
   /**
    *pagination null 
    */
   -------------------------------------------------------------
      IF p_json_clob IS NULL THEN
          error_handling_pkg_3.raise_error('PAGINATION_NULL');
      END IF;

   -------------------------------------------------------------
/**
 *pagination_invalid_json
 */
------------------------------------------------------------
      BEGIN
          l_data_array := JSON_ARRAY_T.parse(p_json_clob);
      EXCEPTION
          WHEN OTHERS THEN
              error_handling_pkg_3.raise_error('PAGINATION_INVALID_JSON');
      END;

      IF l_data_array IS NULL OR l_data_array.get_size = 0 THEN
          error_handling_pkg_3.raise_error('PAGINATION_NO_ARRAY');
      END IF;

     ----------validation
validate_offset (p_offset);
validate_limit(p_limit);
---------------------------------------------------
/**
 *Calculate total_count, slice data, generate links, and build JSON success
 */
------------------------------------------------------------------------------ 
     l_total_count := count_items(l_data_array);
      l_end_index := LEAST(p_offset + p_limit, l_total_count);
      FOR i IN p_offset + 1 .. l_end_index LOOP
          l_slice_array.append(l_data_array.get(i - 1));
      END LOOP;


  
 ----------------------------------
/**
 *Successful exit
 */
------------------------------------------
      l_json_obj.put('status','success');
      l_json_obj.put('data', l_slice_array);

      l_pagination_obj.put('limit', p_limit);
      l_pagination_obj.put('offset', p_offset);
      l_pagination_obj.put('count', l_slice_array.get_size);
      l_pagination_obj.put('hasMore', has_next_page(p_offset, p_limit, l_total_count));
      l_pagination_obj.put('total', l_total_count);
      l_pagination_obj.put('links', build_pagination_links(p_path, p_offset, p_limit, l_total_count));

      l_json_obj.put('pagination', l_pagination_obj);

      RETURN l_json_obj.to_clob();

EXCEPTION
    WHEN OTHERS THEN
        DECLARE
            l_err_code VARCHAR2(4000);
        BEGIN
            IF SQLERRM LIKE '%PAGINATION_%' THEN
                l_err_code := REGEXP_SUBSTR(SQLERRM, 'PAGINATION_\w+');
            ELSE
                l_err_code := 'INTERNAL_SERVER_ERROR';
            END IF;

            error_handling_pkg_3.handle_error(
                p_error_code  => l_err_code,
                p_path        => p_path,
                p_status_code => l_status_code
            );

            RETURN error_handling_pkg_3.generate_error_json(l_err_code, p_path);
        END;

  END get_paginated_data_from_clob;

END pagination_pkg_opt;




>>>>>>> 2208d59dd51246d4039a834f1ef5c66757f45b8d
