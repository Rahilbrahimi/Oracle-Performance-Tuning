
# پروژه ساخت REST API با Oracle REST Data Services (ORDS) و APEX

## معرفی پروژه
در این پروژه، یک REST API ساده برای جدول `customers1` در دیتابیس Oracle با استفاده از ORDS و ابزار مدیریت RESTful Services در Oracle APEX ساخته شده است.  
هدف یادگیری گام‌به‌گام ساخت API و آشنایی با محیط‌های Tomcat و Postman برای تست APIها است.

## پیش‌نیازها
- دسترسی به Oracle APEX (مثلاً https://apex.oracle.com)  
- وجود جدول `customers1` در اسکیمای دیتابیس (مثلاً `WKSP_BLU`)  
- آشنایی پایه با SQL و PL/SQL  
- نصب و استفاده از Postman برای تست APIها

## مراحل انجام پروژه

### ۱. ایجاد RESTful Service Module
- ورود به SQL Workshop → RESTful Services در Oracle APEX  
- ایجاد ماژول جدید با نام `customer_module` و Base Path برابر با `/customers`

### ۲. ایجاد Template و Handler برای GET
- ایجاد Template به نام `list` در ماژول ساخته شده  
- تعریف Handler با Method برابر `GET` و Source Type برابر `Query`  
- وارد کردن کوئری زیر به عنوان منبع داده:

```sql
SELECT id, name, email FROM customers1;
```

- تنظیم Pagination Size روی 50

### ۳. ایجاد Handler برای POST
- در همان Template، ایجاد Handler با Method برابر `POST` و Source Type برابر `PL/SQL Block`  
- وارد کردن کد PL/SQL زیر برای درج داده:

```plsql
BEGIN
  INSERT INTO customers1 (name, email)
  VALUES (:name, :email);
  COMMIT;
END;
```

## تست APIها با Postman

- **GET Request**  
  - Method: GET  
  - URL:  
    ```
    https://apex.oracle.com/pls/apex/ords1_schema/customers/list
    ```  
  - هیچ داده‌ای در Body ارسال نمی‌شود  
  - ارسال درخواست و مشاهده خروجی JSON

- **POST Request**  
  - Method: POST  
  - URL:  
    ```
    https://apex.oracle.com/pls/apex/ords1_schema/customers/add
    ```  
  - Body (فرمت JSON):

```json
{
  "name": "Ali Reza",
  "email": "ali@example.com"
}
```

  - ارسال درخواست و تایید ثبت موفق داده

## نکات مهم و مشکلات برطرف شده

- استفاده از alias صحیح (`ords1_schema`) در URLهای API  
- عدم ارسال Body در درخواست‌های GET  
- حل خطای 500 با اطمینان از صحت کوئری SQL و تست در SQL Workshop  
- تایید دسترسی SELECT برای کاربری که API با آن اجرا می‌شود (مالک جدول بودن در اینجا کافی است)

## جمع‌بندی

در این مرحله، یک REST API ساده با دو عملیات پایه GET و POST ساخته و تست شده است.  
مراحل بعدی شامل افزودن پارامترهای مسیر، احراز هویت (Authentication)، و نصب و پیکربندی ORDS روی سرورهای Tomcat و Nginx خواهد بود.

## منابع و لینک‌های مفید
- [Oracle APEX](https://apex.oracle.com)  
- [Oracle REST Data Services Documentation](https://docs.oracle.com/en/database/oracle/oracle-rest-data-services/index.html)  
- [Postman](https://www.postman.com)

---

## ادامه مسیر

اگر مایل باشی، در مراحل بعدی می‌توانیم:  
- ساخت APIهای با پارامترهای ورودی (مثلاً `/customers/{id}`)  
- تولید مستندات Swagger  
- آموزش نصب و کانفیگ ORDS روی Tomcat و Nginx  
را با هم دنبال کنیم.

---

**تهیه شده توسط:** راحله ابراهیمی  
**تاریخ:** ۲۰۲۵

