---mostand git:
git config --global user.name "نام شما"
git config --global user.email "ایمیل شما"


--vorod be masir porozhe:
cd Desktop/procedure-transaction


--baresi mohtaviyat pushe feli:
ls

--meghdar dahi avaliye:
git init


---ezafe kardan fileha va sabt commit:
git add .
git commit -m "Initial commit"


--etesal be github:
https://github.com/username/repo-name.git



---etesal:
git remote add origin https://github.com/username/repo-name.git


--push kardan baraye avalin bar:
git push -u origin master


--age branch feli main hast darim:
git push -u origin main


---baraye didan branch feli:
git branch


--baraye taghir nam brnach chon bazi vaghtha nemishe pull kard:
git branch -M main
git push -u origin main


---baraye pull kardan:
git pull origin main --allow-unrelated-histories
git push -u origin main


---age mikhay mohtaviyat local kamel jaygozin beshe darim:
git push -u origin main --force

--mohem:
---har bar ke taghir jadid darim:

git add .
git commit -m "توضیح تغییرات"
git push



---kholase masir koli:
cd مسیر/پروژه
git init
git add .
git commit -m "Initial commit"
git remote add origin آدرس-مخزن-GitHub
git push -u origin برنچ


--baraye clone kardan darim:
--dar terminal be masiri ke mikhay prozhe clone beshe boro:
cd مسیر/موردنظر

--dastoor clone:
git clone https://github.com/username/repo-name.git

---bad az clone vared porozhe besho:
cd repo-name
