---
type: person
name: 
middlename: 
surname: 
maidenname: 
aliases: 
sex: 
birthdate: 
birthplace: 
pesel: 
circle: 
profile: 
tags: 
phone: 
email: 
address: 
created: <% tp.date.now("YYYY-MM-DDTHH:mm") %>
uuid: <% tp.user.uuid() %>
cssclasses:
  - file-person
company:
---
```dataviewjs
const {PersonInfo} = await cJS(); PersonInfo.printInfo(dv);
```
<% tp.file.cursor(1) %>
```dataviewjs
const {PersonInfo} = await cJS(); PersonInfo.printDataview(dv);
```
