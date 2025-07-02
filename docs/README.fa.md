
# 🔍 بررسی و تحلیل Performance دیتابیس Oracle

این یادداشت یک راهنمای گام‌به‌گام برای بررسی کامل عملکرد یک دیتابیس Oracle است. هدف من اینه که شناسایی گلوگاه‌ها، رفتار نادرست کوئری‌ها، ساختار ناسازگار دیتابیس و ارائه پیشنهادهای بهینه‌سازی است.

### 🎯 ساختار کلی تحلیل Performance

بررسی عملکرد دیتابیس را می‌تونم در سه لایه اصلی دسته‌بندی کرد:

1. **زیرساخت و مدیریت فضا** (Tablespace, TEMP, Undo)
2. **رفتار زمان اجرا و کوئری‌ها** (Waits, SQLs, Plans)
3. **طراحی منطقی دیتابیس و مدل داده** (Index, Partitioning, Stats)

### 🧩 مرحله ۱: بررسی مدیریت فضا و زیرساخت دیتابیس

###### ➕ بررسی وضعیت Tablespace و فایل‌های داده

```--SQL
SELECT 
    df.tablespace_name,
    df.file_name,
    ROUND(df.bytes/1024/1024) AS current_size_mb,
    ROUND(df.maxbytes/1024/1024) AS max_size_mb,
    df.autoextensible,
    ROUND(fs.free_space_mb) AS free_space_mb
FROM 
    dba_data_files df
JOIN (
    SELECT 
        tablespace_name,
        ROUND(SUM(bytes)/1024/1024) AS free_space_mb
    FROM 
        dba_free_space
    GROUP BY tablespace_name
) fs
ON df.tablespace_name = fs.tablespace_name
ORDER BY df.tablespace_name, df.file_name;
```

###### ➕ بررسی TEMP Tablespace و مصرف آن

```--SQL
SELECT 
    tablespace_name,
    SUM(blocks) * TO_NUMBER(value)/1024/1024 AS used_mb
FROM 
    v$sort_usage, v$parameter
WHERE 
    name = 'db_block_size'
GROUP BY 
    tablespace_name, value;
```

###### ➕ بررسی Undo Tablespace و پارامترهای مرتبط

```--SQL
SELECT 
    tablespace_name, 
    file_name,
    autoextensible,
    ROUND(bytes/1024/1024) AS size_mb,
    ROUND(maxbytes/1024/1024) AS max_size_mb
FROM 
    dba_data_files
WHERE 
    tablespace_name = (
        SELECT value 
        FROM v$parameter 
        WHERE name = 'undo_tablespace'
    );
```

```--SQL
SELECT 
    name, value
FROM 
    v$parameter
WHERE 
    name IN ('undo_retention', 'undo_tablespace');
```

###### ➕ بررسی Fragmentation در جدول‌ها و ایندکس‌ها

```--SQL
SELECT 
    segment_name,
    segment_type,
    tablespace_name,
    ROUND(bytes/1024/1024) AS size_mb,
    extents
FROM 
    dba_segments
WHERE 
    segment_type IN ('TABLE', 'INDEX')
ORDER BY 
    extents DESC;
```

### 🧩 مرحله ۲: بررسی رفتار سیستم و Sessionها

###### ➕ بررسی Top Wait Events

```--SQL
SELECT 
    event, 
    total_waits, 
    time_waited/100 AS time_waited_sec, 
    average_wait, 
    wait_class
FROM 
    v$system_event
WHERE 
    wait_class <> 'Idle'
ORDER BY 
    time_waited DESC
FETCH FIRST 20 ROWS ONLY;
```

###### ➕ شناسایی SQLهای کند یا پرتکرار

```--SQL
SELECT 
    sql_id,
    plan_hash_value,
    parsing_schema_name,
    module,
    buffer_gets,
    disk_reads,
    cpu_time/1000000 AS cpu_sec,
    elapsed_time/1000000 AS elapsed_sec,
    executions,
    sql_text
FROM 
    v$sql
WHERE 
    elapsed_time > 1000000
ORDER BY 
    elapsed_time DESC
FETCH FIRST 20 ROWS ONLY;
```

###### ➕ بررسی کوئری‌های بدون Bind Variable (Hard Parse زیاد)

```--SQL
SELECT 
    sql_id,
    parsing_schema_name,
    executions,
    sql_text
FROM 
    v$sql
WHERE 
    sql_text NOT LIKE '%:%' 
    AND executions > 10
ORDER BY 
    executions DESC;
```

###### ➕ بررسی آمار Hard Parse

```--SQL
SELECT 
    name, value 
FROM 
    v$sysstat
WHERE 
    name LIKE '%parse%';
```

### 🧩 مرحله ۳: بررسی ایندکس‌ها، Execution Plan، و Partitioning

###### ➕ بررسی ایندکس‌های تعریف‌شده روی جدول‌ها

```--SQL
SELECT 
    owner,
    index_name,
    table_name,
    status,
    index_type,
    uniqueness,
    last_analyzed,
    num_rows,
    leaf_blocks,
    DISTINCT_KEYS
FROM 
    dba_indexes
WHERE 
    owner NOT IN ('SYS', 'SYSTEM')
ORDER BY 
    num_rows DESC;
```

###### ➕ بررسی استفاده واقعی از ایندکس‌ها (logical/physical reads)

```--SQL
SELECT 
    object_name, 
    statistic_name, 
    value
FROM 
    v$segment_statistics
WHERE 
    object_type = 'INDEX'
    AND statistic_name IN ('logical reads', 'physical reads')
ORDER BY 
    value DESC;
```

###### ➕ مشاهده Execution Plan با SQL ID

```--SQL
SELECT * 
FROM table(DBMS_XPLAN.DISPLAY_CURSOR('your_sql_id_here', 0, 'ALLSTATS LAST'));
```

###### ➕ بررسی وجود Partition در جدول‌ها

```--SQL
SELECT 
    table_owner,
    table_name,
    partitioning_type,
    subpartitioning_type,
    partition_count,
    def_tablespace_name
FROM 
    dba_part_tables
ORDER BY 
    partition_count DESC;
```

### 🧩 مرحله ۴: بررسی آمار جدول‌ها و Gather Statistics

###### ➕ بررسی تاریخ آخرین آنالیز جدول‌ها

```--SQL
SELECT 
    table_name, 
    num_rows, 
    last_analyzed 
FROM 
    dba_tables
WHERE 
    owner = 'SCHEMA_NAME'
ORDER BY 
    last_analyzed;
```

###### ➕ اجرای Gather Statistics روی اسکیما

```--SQL
BEGIN
  DBMS_STATS.GATHER_SCHEMA_STATS('SCHEMA_NAME');
END;
```

### 📋 ترتیبی که به نظرم منطقی‌تره برای اجرا

| گام | عملیات |
|-----|--------|
| 1️⃣ | بررسی Tablespace و Fragmentation |
| 2️⃣ | بررسی وضعیت TEMP و Undo |
| 3️⃣ | بررسی Memory و پارامترهای مربوطه |
| 4️⃣ | شناسایی Top Wait Events |
| 5️⃣ | شناسایی SQLهای پرهزینه |
| 6️⃣ | بررسی Execution Plan |
| 7️⃣ | تحلیل ایندکس‌ها و Partition |
| 8️⃣ | به‌روزرسانی آمار و پیشنهادات نهایی |

### 🧠 نکات تکمیلی قابل بررسی:

- بررسی PGA و SGA برای مدیریت بهتر حافظه
- بررسی Redo log و log file sync
- استفاده از Materialized View برای caching
- بررسی Parallel Query و تنظیمات مرتبط
- بررسی استفاده از Hint در SQLها

