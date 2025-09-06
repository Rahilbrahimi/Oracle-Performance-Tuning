create or replace PACKAGE pagination_pkg_opt AS

  FUNCTION update_url_with_pagination(
      p_url    IN VARCHAR2,
      p_offset IN NUMBER,
      p_limit  IN NUMBER
  ) RETURN VARCHAR2;
  FUNCTION get_paginated_data_from_clob(
      p_json_clob IN CLOB,
      p_offset    IN NUMBER DEFAULT 0,
      p_limit     IN NUMBER DEFAULT 100,
      p_path      IN VARCHAR2 DEFAULT '/api/v1/data'
  ) RETURN CLOB;
END pagination_pkg_opt;
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
