---
<%*
j = tp.user.makejournal(tp.file.title)
-%>
type: journal
kind: <% j.kind %>
title: <% j.title %>
aliases: <% j.aliases %>
tags: <% j.tags %>
<% j.frontmatter %>
created: <% j.now %>
uuid: <% tp.user.uuid() %>
cssclasses: <% j.cssclasses %>
summary: 
---
## <% j.header %>
<% j.nav %>
```dataviewjs
const {JournalInfo} = await cJS(); await JournalInfo.printInfo(dv);
```
...<% tp.file.cursor(1) %>
```dataviewjs
const {JournalInfo} = await cJS(); await JournalInfo.printDataview(dv);
```
