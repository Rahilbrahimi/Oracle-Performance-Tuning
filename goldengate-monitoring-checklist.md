
# ✅ چک‌لیست کامل مانیتورینگ و رسیدگی به اینسیدنت‌های Oracle GoldenGate

> این چک‌لیست شامل دو بخش است:
> - مانیتورینگ روزانه سیستم
> - گام به گام رسیدگی به اینسیدنت‌ها به صورت عملیاتی

---

## 🟢 بخش اول: مانیتورینگ روزانه سلامت سیستم

| ردیف | مورد بررسی | دستور یا توضیح |
|------|-------------|----------------|
| 1 | بررسی وضعیت کلی فرآیندها | `info all` |
| 2 | بررسی lag تمام Extractها | `lag extract *` |
| 3 | بررسی lag تمام Replicatها | `lag replicat *` |
| 4 | مشاهده checkpoint هر Extract | `info extract <name>, showch` |
| 5 | بررسی خطاها در لاگ گلوبال | `tail -100f ggserr.log` |
| 6 | بررسی گزارش اجرای فرآیندها | `view report <name>` |
| 7 | بررسی فضای trail files | `ll dirdat/` یا `du -sh dirdat/` |
| 8 | بررسی اتصال به CredentialStore | `dblogin useridalias <alias> domain <domain>` |
| 9 | بررسی فعال بودن MGR | `info mgr` |
| 10 | تست اتصال به دیتابیس | `tnsping <service>` یا `sqlplus` |

---

## 🔴 بخش دوم: رسیدگی به اینسیدنت‌ها (گام‌به‌گام عملیاتی)

### 📌 سناریو 1: Lag بالا در Extract یا Replicat

1. بررسی میزان lag:
   ```bash
   lag extract *
   lag replicat *
   ```

2. بررسی جزئیات lag و checkpoint:
   ```bash
   info extract <name>, showch
   info replicat <name>, showch
   ```

3. بررسی گزارش فرآیند:
   ```bash
   view report <name>
   ```

4. بررسی وضعیت فایل‌های trail:
   ```bash
   ll dirdat/
   du -sh dirdat/
   ```

5. بررسی حجم تراکنش در Oracle:
   ```sql
   select * from v$active_session_history where sample_time > sysdate - 1/24/12;
   ```

6. بررسی I/O سیستم:
   ```bash
   iostat -x 1 5
   ```

7. بررسی lockهای دیتابیس:
   ```sql
   select * from v$session where blocking_session is not null;
   ```

---

### 📌 سناریو 2: فرآیند Abended شده

1. بررسی وضعیت با:
   ```bash
   info all
   ```

2. مشاهده گزارش دقیق:
   ```bash
   view report <name>
   ```

3. بررسی لاگ اصلی:
   ```bash
   tail -100f ggserr.log
   ```

4. اصلاح پارامتر فایل در:
   ```bash
   vi dirprm/<name>.prm
   ```

5. اجرای مجدد:
   ```bash
   start extract <name>
   start replicat <name>
   ```

---

### 📌 سناریو 3: عدم تولید فایل trail

1. بررسی فضای دیسک:
   ```bash
   df -h
   ```

2. بررسی حجم trailها:
   ```bash
   du -sh ./dirdat/
   ```

3. بررسی مجوز فایل و پوشه:
   ```bash
   ls -l dirdat/
   ```

4. بررسی exttrail و rmttrail در فایل‌های prm

---

### 📌 سناریو 4: مشکل در اتصال به دیتابیس

1. تست اتصال با alias:
   ```bash
   dblogin useridalias <alias> domain <domain>
   ```

2. بررسی فایل TNS:
   ```bash
   cat $TNS_ADMIN/tnsnames.ora
   ```

3. تست اتصال:
   ```bash
   tnsping <service>
   sqlplus user@service
   ```

---

### 📌 سناریو 5: داده منتقل نمی‌شود یا جدول مقصد آپدیت نمی‌شود

1. بررسی گزارش Replicat:
   ```bash
   view report <replicat>
   ```

2. بررسی mapping و colmap در param file

3. فعال بودن trigger در مقصد؟
   استفاده از:
   ```ini
   dboptions suppressreport
   ```

4. در صورت تفاوت ساختار جداول:
   ```ini
   COLMAP (col1 = colA, col2 = colB)
   ```

---

## 📁 فایل‌های مهم گلدن گیت

| مسیر | توضیح |
|------|--------|
| `ggserr.log` | لاگ کلی خطاها |
| `dirrpt/` | گزارش‌های Extract و Replicat |
| `dirprm/` | فایل پارامتر فرآیندها |
| `dirdat/` | مسیر فایل‌های trail |
| `dirdsc/` | فایل‌های discard |

---

## 📝 پیشنهاد برای کار روزانه

- ایجاد لاگ روزانه در مسیر:
  ```
  logs/ogg_monitor_YYYYMMDD.log
  ```
- ثبت وضعیت `info all`، lag و گزارش فایل‌ها
