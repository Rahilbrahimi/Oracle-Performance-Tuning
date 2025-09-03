CREATE OR REPLACE PACKAGE pagination_pkg_opt AS

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

CREATE OR REPLACE PACKAGE BODY pagination_pkg_opt AS

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
      -- بررسی وجود offset
      IF REGEXP_INSTR(l_url, '([?&]offset=)') > 0 THEN
          has_offset := TRUE;
          l_url := REGEXP_REPLACE(l_url, '([?&]offset=)([^&]*)', '\1' || l_offset);
      END IF;

      -- بررسی وجود limit
      IF REGEXP_INSTR(l_url, '([?&]limit=)') > 0 THEN
          has_limit := TRUE;
          l_url := REGEXP_REPLACE(l_url, '([?&]limit=)([^&]*)', '\1' || l_limit);
      END IF;

      -- offset بدون limit
      IF has_offset AND NOT has_limit THEN
          l_url := REGEXP_REPLACE(l_url, '(offset=\d+)', '\1&limit=' || l_limit);
      END IF;

      -- limit بدون offset
      IF has_limit AND NOT has_offset THEN
          l_url := REGEXP_REPLACE(l_url, '([?&])limit=', '\1offset=' || l_offset || CHR(38) || 'limit=');
      END IF;

      -- هیچکدام موجود نیست
      IF NOT has_offset AND NOT has_limit THEN
          IF INSTR(l_url, '?') > 0 THEN
              l_url := l_url || CHR(38) || 'offset=' || l_offset || CHR(38) || 'limit=' || l_limit;
          ELSE
              l_url := l_url || CHR(63) || 'offset=' || l_offset || CHR(38) || 'limit=' || l_limit;
          END IF;
      END IF;

      RETURN l_url;
  END update_url_with_pagination;

  -- تابع اصلی pagination روی CLOB JSON
  FUNCTION get_paginated_data_from_clob(
      p_json_clob IN CLOB,
      p_offset    IN NUMBER DEFAULT 0,
      p_limit     IN NUMBER DEFAULT 100,
      p_path      IN VARCHAR2 DEFAULT '/api/v1/data'
  ) RETURN CLOB IS
      l_json_obj       JSON_OBJECT_T := NEW JSON_OBJECT_T();
      l_data_array     JSON_ARRAY_T := NEW JSON_ARRAY_T();
      l_pagination_obj JSON_OBJECT_T := NEW JSON_OBJECT_T();
      l_links_array    JSON_ARRAY_T := NEW JSON_ARRAY_T();
      l_total_count    NUMBER;
      l_end_index      NUMBER;
      l_slice_array    JSON_ARRAY_T := NEW JSON_ARRAY_T();
      l_link_obj       JSON_OBJECT_T;
      l_status_code    NUMBER;
  BEGIN
      -- شرط 1: CLOB نباید NULL باشد
      IF p_json_clob IS NULL THEN
          error_handling_pkg_3.raise_error('PAG_NULL_CLOB');
      END IF;

      -- تبدیل CLOB به JSON_ARRAY و بررسی صحت JSON
      BEGIN
          l_data_array := JSON_ARRAY_T.parse(p_json_clob);
      EXCEPTION
          WHEN OTHERS THEN
              error_handling_pkg_3.raise_error('PAG_INVALID_JSON');
      END;

      -- شرط 2: بررسی اینکه JSON از نوع Array باشد
      IF l_data_array IS NULL THEN
          error_handling_pkg_3.raise_error('PAG_NOT_ARRAY');
      END IF;

      -- شرط 3: بررسی offset و limit
      IF p_offset < 0 THEN
          error_handling_pkg_3.raise_error('PAG_INVALID_OFFSET');
      END IF;
      IF p_limit < 1 THEN
          error_handling_pkg_3.raise_error('PAG_INVALID_LIMIT');
      END IF;

      l_total_count := l_data_array.get_size;

      -- تعیین محدوده slice
      l_end_index := LEAST(p_offset + p_limit, l_total_count);

      -- Slice کردن داده‌ها
      FOR i IN p_offset + 1 .. l_end_index LOOP
          l_slice_array.append(l_data_array.get(i - 1)); -- JSON_ARRAY_T از 0 ایندکس می‌شود
      END LOOP;

      -- ساخت لینک‌ها
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

      -- ✅ لینک آخرین صفحه
      IF l_total_count > p_limit THEN
          l_link_obj := NEW JSON_OBJECT_T();
          l_link_obj.put('rel','last');
          l_link_obj.put(
              'href',
              update_url_with_pagination(
                  p_path,
                  (TRUNC((l_total_count - 1) / p_limit) * p_limit),
                  p_limit
              )
          );
          l_links_array.append(l_link_obj);
      END IF;

      -- ساخت JSON خروجی
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
          error_handling_pkg_3.handle_error(NULL, p_path, l_status_code);
          RETURN error_handling_pkg_3.generate_error_json(NULL, p_path);
  END get_paginated_data_from_clob;
END pagination_pkg_opt;



