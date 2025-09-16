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

  -- تابع update_url_with_pagination
  FUNCTION update_url_with_pagination(
      p_url    IN VARCHAR2,
      p_offset IN NUMBER,
      p_limit  IN NUMBER
  ) RETURN VARCHAR2 IS
      l_url       VARCHAR2(4000) := p_url;
      l_offset    VARCHAR2(50) := TO_CHAR(p_offset);
      l_limit     VARCHAR2(50) := TO_CHAR(p_limit);
      has_offset  BOOLEAN := FALSE;
      has_limit   BOOLEAN := FALSE;
  BEGIN
      -- Checking for existence of offset
      IF REGEXP_INSTR(l_url, '([?&]offset=)') > 0 THEN
          has_offset := TRUE;
          l_url := REGEXP_REPLACE(l_url, '([?&]offset=)([^&]*)', '\1' || l_offset);
      END IF;

      -- Checking for existence of limit
      IF REGEXP_INSTR(l_url, '([?&]limit=)') > 0 THEN
          has_limit := TRUE;
          l_url := REGEXP_REPLACE(l_url, '([?&]limit=)([^&]*)', '\1' || l_limit);
      END IF;

      -- There is an offset but no limit
      IF has_offset AND NOT has_limit THEN
          l_url := REGEXP_REPLACE(l_url, '(offset=' || l_offset || ')', '\1&limit=' || l_limit);
      END IF;

      -- There is a limit but no offset
      IF has_limit AND NOT has_offset THEN
          l_url := REGEXP_REPLACE(l_url,
                                  '([?&])limit=',
                                  '\1offset=' || l_offset || CHR(38) || 'limit=');
      END IF;

      -- No limit, no offset
      IF NOT has_offset AND NOT has_limit THEN
          IF INSTR(l_url, '?') > 0 THEN
              l_url := l_url || CHR(38) || 'offset=' || l_offset || CHR(38) || 'limit=' || l_limit;
          ELSE
              l_url := l_url || CHR(63) || 'offset=' || l_offset || CHR(38) || 'limit=' || l_limit;
          END IF;
      END IF;

      RETURN l_url;
  END update_url_with_pagination;

  -- تابع اصلی pagination
  FUNCTION get_paginated_data_from_clob(
      p_json_clob IN CLOB,
      p_offset    IN NUMBER DEFAULT 0,
      p_limit     IN NUMBER DEFAULT 100,
      p_path      IN VARCHAR2 DEFAULT '/api/v1/data'
  ) RETURN CLOB IS
      l_json_obj       JSON_OBJECT_T := NEW JSON_OBJECT_T();
      l_data_array     JSON_ARRAY_T;
      l_pagination_obj JSON_OBJECT_T := NEW JSON_OBJECT_T();
      l_links_array    JSON_ARRAY_T := NEW JSON_ARRAY_T();
      l_total_count    NUMBER;
      l_end_index      NUMBER;
      l_slice_array    JSON_ARRAY_T := NEW JSON_ARRAY_T();
      l_link_obj       JSON_OBJECT_T;
      l_status_code    NUMBER;
  BEGIN
      -- شرط 1: ورودی نباید NULL باشد
      IF p_json_clob IS NULL THEN
          error_handling_pkg_3.raise_error('PAGINATION_NULL');
      END IF;

      -- شرط 2: ورودی باید JSON معتبر از نوع Array باشد
      BEGIN
          l_data_array := JSON_ARRAY_T.parse(p_json_clob);
      EXCEPTION
          WHEN OTHERS THEN
              error_handling_pkg_3.raise_error('PAGINATION_INVALID_JSON');
      END;

      IF l_data_array IS NULL OR l_data_array.get_size = 0 THEN
          error_handling_pkg_3.raise_error('PAGINATION_NO_ARRAY');
      END IF;

      -- شرط 3: بررسی offset و limit
      IF p_offset < 0 OR p_limit < 1 THEN
          error_handling_pkg_3.raise_error('PAGINATION_LIMIT_ERR');
      END IF;

      -- محاسبه total_count، slice کردن داده‌ها، تولید لینک‌ها، و ساخت JSON موفقیت
      l_total_count := l_data_array.get_size;
      l_end_index := LEAST(p_offset + p_limit, l_total_count);

      FOR i IN p_offset + 1 .. l_end_index LOOP
          l_slice_array.append(l_data_array.get(i - 1));
      END LOOP;

      -- لینک‌ها
      l_link_obj := NEW JSON_OBJECT_T();
      l_link_obj.put('rel','self');
      l_link_obj.put('href', update_url_with_pagination(p_path, p_offset, p_limit));
      l_links_array.append(l_link_obj);

      l_link_obj := NEW JSON_OBJECT_T();
      l_link_obj.put('rel','first');
      l_link_obj.put('href', update_url_with_pagination(p_path, 0, p_limit));
      l_links_array.append(l_link_obj);

      IF p_offset > 0 THEN
          l_link_obj := NEW JSON_OBJECT_T();
          l_link_obj.put('rel','previous');
          l_link_obj.put('href', update_url_with_pagination(p_path, GREATEST(p_offset - p_limit, 0), p_limit));
          l_links_array.append(l_link_obj);
      END IF;

      IF (p_offset + p_limit) < l_total_count THEN
          l_link_obj := NEW JSON_OBJECT_T();
          l_link_obj.put('rel','next');
          l_link_obj.put('href', update_url_with_pagination(p_path, p_offset + p_limit, p_limit));
          l_links_array.append(l_link_obj);
      END IF;

      IF l_total_count > p_limit THEN
          l_link_obj := NEW JSON_OBJECT_T();
          l_link_obj.put('rel','last');
          l_link_obj.put('href', update_url_with_pagination(
              p_path,
              (TRUNC((l_total_count - 1) / p_limit) * p_limit),
              p_limit
          ));
          l_links_array.append(l_link_obj);
      END IF;

      -- خروجی موفق
      l_json_obj.put('status','success');
      l_json_obj.put('data', l_slice_array);
      l_pagination_obj.put('limit', p_limit);
      l_pagination_obj.put('offset', p_offset);
      l_pagination_obj.put('count', l_slice_array.get_size);
      l_pagination_obj.put('hasMore', (p_offset + p_limit) < l_total_count);
      l_pagination_obj.put('total', l_total_count);
      l_pagination_obj.put('links', l_links_array);
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

