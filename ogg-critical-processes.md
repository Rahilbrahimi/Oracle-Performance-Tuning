
# 📊 مستندسازی OGGهای پرتکرار و حساس + راهکارهای رفع مشکل

> این فایل شامل OGGهایی است که در پروژه یا سازمان شما بیشترین میزان مشکل (lag, abended, apply error و ...) را داشته‌اند به همراه راهکارهای پیشنهادی برای تحلیل و رفع آن‌ها.

---

## 🔹 OGGهای حساس و پرتکرار (مثال‌ها)

| نام OGG | نوع | توضیح | مشکلات رایج | وضعیت کنونی |
|---------|-----|--------|----------------|----------------|
| `ext_hr` | Extract | خواندن داده از PDB `rebrahimi` | Lag بالا، توقف ناگهانی | فعال (Lag کنترل شده) |
| `pmp_hr` | Pump | ارسال trail به سرور مقصد | عدم تولید فایل، توقف به‌دلیل حجم بالا | فعال (نسبتاً پایدار) |
| `rep_hr` | Replicat | اعمال داده به `rebrahimi2` | خطا در mapping یا trigger | در حال بررسی (توقف مقطعی) |
| `rpl_acc` | Replicat | برای جدول حساب‌ها | خطای کلید اصلی، خطای زمان apply | نیاز به اصلاح colmap |
| `ext_core` | Extract | برای core banking | توقف در زمان ترافیک زیاد | پیشنهاد: افزایش memory + parallelism |

---

## ✅ اقدامات پیشنهادی برای این OGGها

### 🔍 بررسی OGG پرتکرار `ext_hr`

- دستورات:
  ```bash
  info extract ext_hr, showch
  view report ext_hr
  tail -100f ggserr.log
  ```

- بهبودها:
  - کاهش حجم جدول‌ها (فقط جدول‌های لازم)
  - استفاده از `TRANLOGOPTIONS EXCLUDEUSER` برای حذف کاربران غیرمهم
  - تنظیم صحیح `CACHEMGR`

---

### 🔍 بررسی OGG `rep_hr`

- مشکلات رایج:
  - تفاوت ساختار جدول مبدا و مقصد
  - اجرای triggerها باعث تاخیر و خطا می‌شود

- اقدامات اصلاحی:
  ```ini
  assumetargetdefs
  dboptions suppressreport
  map src.table, target dest.table, colmap(...);
  ```

---

### 🔧 پیشنهادات کلی برای پایداری OGGهای حساس

| دسته اقدام | جزئیات |
|------------|--------|
| Parallel Replicat | استفاده از `Integrated Replicat` برای پردازش موازی |
| Log Retention | نگهداری بیشتر فایل‌های `trail` (افزایش فضای `dirdat`) |
| مانیتورینگ خودکار | تعریف alert روی lag > 10 دقیقه |
| افزایش منابع سیستم | CPU، I/O، و حافظه مخصوصاً در لحظات پیک |

---

## 📂 مسیر ثبت گزارش‌های روزانه این OGGها

پیشنهاد می‌شود برای هر OGG حساس، پوشه مجزا داشته باشید:

```
ogg_logs/
├── ext_hr/
│   ├── report_2025-07-05.txt
│   └── lag_history.log
├── rep_hr/
│   ├── errors.txt
│   └── restart.log
```

---

## 📌 TODO

- بررسی امکان انتقال `rep_hr` به حالت **Integrated Replicat**
- تحلیل خطاهای `rpl_acc` با استفاده از `discardfile`
- مستندسازی دقیق mapping‌های متفاوت

