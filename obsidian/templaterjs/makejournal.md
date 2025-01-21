# obsidian-journal
Javascript template for Obsidian's Templater that automatically creates stubs for days,  month and years.

## Requirements
- [Templater](https://github.com/SilentVoid13/Templater)
- [Dataview](https://github.com/blacksmithgu/obsidian-dataview)

## Properties

### For day-notes

- thisDay
- nextDay
- prevDay
- thisMonth
- thisYear

### For month-notes

- thisMonth
- nextMonth
- prevMonth
- thisYear

### For year-notes

- thisYear
- nextYear
- prevYear

### For day properties (thisDay, etc.)

- date
- year
- month
- day
- dayInt
- dow (day of week)
- doy (day of year)
- name
- nameEn
- fullName
- fullNameEn
- path
- link
- linkName
- lifedays

### For month properties (thisMonth, etc.)

- year
- month
- monthInt
- name
- nameEn
- nameGen
- fullName
- fullNameEn
- days
- firstDay
- firstDayDow
- lastDay
- lastDayDow
- path
- link
- linkGen

### For year properties (thisYear, etc.)

- year
- days
- isLeap
- path
- link

