CREATE OR REPLACE PROCEDURE get_transaction_3 (
    p_account_no     IN  VARCHAR2,
    p_from_timestamp IN  VARCHAR2,
    p_to_timestamp   IN  VARCHAR2,
    p_page_number    IN  VARCHAR2 DEFAULT '0',
    p_page_size      IN  VARCHAR2 DEFAULT '100',
    i_result         OUT CLOB
) AS
    l_account_no     VARCHAR2(50);
    l_from_str       VARCHAR2(50);
    l_to_str         VARCHAR2(50);
    l_from_timestamp TIMESTAMP;
    l_to_timestamp   TIMESTAMP;
    l_response       CLOB;
    l_total_count    PLS_INTEGER := 0;
    l_size           PLS_INTEGER := 100;
    l_page           PLS_INTEGER := 0;
    l_offset         PLS_INTEGER := 0;
    l_hasmore        VARCHAR2(5) := 'false';
    l_self_link      VARCHAR2(4000);
    l_next_link      VARCHAR2(4000);
    l_prev_link      VARCHAR2(4000);
    l_next_page      PLS_INTEGER;
    l_prev_page      PLS_INTEGER;
BEGIN
   
    -- بررسی ورودیها و ولیدیشن
   
    IF p_account_no IS NULL OR TRIM(p_account_no) = '' THEN
        RAISE_APPLICATION_ERROR(-20000, 'شماره حساب الزامی است');
    END IF;
    IF p_from_timestamp IS NULL OR TRIM(p_from_timestamp) = '' THEN
        RAISE_APPLICATION_ERROR(-20003, 'تاریخ شروع الزامی است');
    END IF;
    IF LENGTH(TRIM(p_account_no)) > 50 THEN
        RAISE_APPLICATION_ERROR(-20004, 'طول شماره حساب نباید بیشتر از 50 کاراکتر باشد');
    END IF;

    l_account_no := TRIM(p_account_no);
    l_from_str   := TRIM(REPLACE(REPLACE(p_from_timestamp, '''', ''), '"', ''));
    l_to_str     := TRIM(REPLACE(REPLACE(NVL(p_to_timestamp,''), '''', ''), '"', ''));

    IF NOT REGEXP_LIKE(l_account_no, '^[0-9]+$') THEN
        RAISE_APPLICATION_ERROR(-20001, 'شماره حساب نامعتبر است. فقط عدد مجاز میباشد.');
    END IF;

    IF NOT REGEXP_LIKE(NVL(p_page_number,'0'), '^\d+$') THEN
        RAISE_APPLICATION_ERROR(-20012, 'شماره صفحه باید عدد صحیح باشد.');
    END IF;
    IF NOT REGEXP_LIKE(NVL(p_page_size,'100'), '^\d+$') THEN
        RAISE_APPLICATION_ERROR(-20013, 'سایز صفحه باید عدد صحیح باشد.');
    END IF;

    l_page := TO_NUMBER(NVL(p_page_number,'0'));
    l_size := TO_NUMBER(NVL(p_page_size,'100'));

    IF l_page < 0 THEN
        RAISE_APPLICATION_ERROR(-20010, 'شماره صفحه نمیتواند منفی باشد');
    END IF;
    IF l_size <= 0 OR l_size > 500 THEN
        RAISE_APPLICATION_ERROR(-20011, 'سایز صفحه باید بین 1 تا 500 باشد');
    END IF;

   
    -- تبدیل و بررسی تاریخها
   
    BEGIN
        l_from_timestamp := TO_TIMESTAMP(l_from_str, 'YYYY-MM-DD HH24:MI:SS');
    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20006, 'فرمت تاریخ شروع اشتباه است. فرمت صحیح: YYYY-MM-DD HH24:MI:SS');
    END;

    IF l_to_str IS NULL OR l_to_str = '' THEN
        l_to_timestamp := l_from_timestamp + INTERVAL '5' MINUTE;
    ELSE
        BEGIN
            l_to_timestamp := TO_TIMESTAMP(l_to_str, 'YYYY-MM-DD HH24:MI:SS');
        EXCEPTION
            WHEN OTHERS THEN
                RAISE_APPLICATION_ERROR(-20006, 'فرمت تاریخ پایان اشتباه است. فرمت صحیح: YYYY-MM-DD HH24:MI:SS');
        END;
    END IF;

    IF l_to_timestamp <= l_from_timestamp THEN
        RAISE_APPLICATION_ERROR(-20007, 'تاریخ پایان باید بعد از تاریخ شروع باشد');
    END IF;
    IF (l_to_timestamp - l_from_timestamp) > INTERVAL '1' DAY THEN
        RAISE_APPLICATION_ERROR(-20002, 'اختلاف زمانی بین تاریخ شروع و پایان نباید بیشتر از 24 ساعت باشد');
    END IF;

    l_offset := l_page * l_size;

   
    -- شمارش کل رکوردها
   
    SELECT COUNT(*)
    INTO l_total_count
    FROM bank_transactions
    WHERE account_number = l_account_no
      AND transaction_date BETWEEN l_from_timestamp AND l_to_timestamp;

    IF (l_offset + l_size) < l_total_count THEN
        l_hasmore := 'true';
    END IF;

   
    -- گرفتن دادهها
   
    SELECT NVL(
               JSON_ARRAYAGG(
                   JSON_OBJECT(
                       'transaction_id'   VALUE transaction_id,
                       'account_number'   VALUE account_number,
                       'amount'           VALUE amount,
                       'transaction_date' VALUE TO_CHAR(transaction_date, 'YYYY-MM-DD"T"HH24:MI:SS')
                   )
               ), '[]')
    INTO l_response
    FROM (
        SELECT *
        FROM bank_transactions
        WHERE account_number = l_account_no
          AND transaction_date BETWEEN l_from_timestamp AND l_to_timestamp
        ORDER BY transaction_date ASC
        OFFSET l_offset ROWS FETCH NEXT l_size ROWS ONLY
    );

   
    -- لینکها
   
    l_self_link := '/transactions?account=' || l_account_no ||
                   CHR(38) || 'page=' || l_page ||
                   CHR(38) || 'size=' || l_size ||
                   CHR(38) || 'from=' || TO_CHAR(l_from_timestamp, 'YYYY-MM-DD HH24:MI:SS') ||
                   CHR(38) || 'to=' || TO_CHAR(l_to_timestamp, 'YYYY-MM-DD HH24:MI:SS');

    IF l_hasmore = 'true' THEN
        l_next_page := l_page + 1;
        l_next_link := '/transactions?account=' || l_account_no ||
                       CHR(38) || 'page=' || l_next_page ||
                       CHR(38) || 'size=' || l_size ||
                       CHR(38) || 'from=' || TO_CHAR(l_from_timestamp, 'YYYY-MM-DD HH24:MI:SS') ||
                       CHR(38) || 'to=' || TO_CHAR(l_to_timestamp, 'YYYY-MM-DD HH24:MI:SS');
    ELSE
        l_next_link := '';
    END IF;

    IF l_page > 0 THEN
        l_prev_page := l_page - 1;
        l_prev_link := '/transactions?account=' || l_account_no ||
                       CHR(38) || 'page=' || l_prev_page ||
                       CHR(38) || 'size=' || l_size ||
                       CHR(38) || 'from=' || TO_CHAR(l_from_timestamp, 'YYYY-MM-DD HH24:MI:SS') ||
                       CHR(38) || 'to=' || TO_CHAR(l_to_timestamp, 'YYYY-MM-DD HH24:MI:SS');
    ELSE
        l_prev_link := '';
    END IF;

   
    -- خروجی نهایی JSON
   
    i_result := TO_CLOB(
        JSON_OBJECT(
            'data'        VALUE l_response FORMAT JSON,
            'total_count' VALUE l_total_count,
            'page'        VALUE l_page,
            'page_size'   VALUE l_size,
            'has_more'    VALUE l_hasmore,
            'links'       VALUE JSON_OBJECT(
                             'self' VALUE l_self_link,
                             'next' VALUE l_next_link,
                             'prev' VALUE l_prev_link
                           )
        )
    );

EXCEPTION
    WHEN OTHERS THEN
        i_result := '{"status":"error","message":"' || REPLACE(SQLERRM, '"', '''') || '"}';
END get_transaction_3;