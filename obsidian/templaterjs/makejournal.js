if (typeof moment === 'undefined') {
    moment = require(require('os').homedir()
 + '/Documents/Scripts/node_modules/moment')
}

String.prototype.cfl = function () {
    return this.charAt(0).toUpperCase() + this.slice(1);
};

class JournalDictionary {
    constructor() {
        this.day = {'pl': 'dzień', 'en': 'day'};
        this.byDays = {'pl': 'dzień po dniu', 'en': 'by days'};
        this.month = {'pl': 'miesiąc', 'en': 'month'};
        this.byMonth = {'pl': 'miesiącami', 'en': 'by months'};
        this.year = {'pl': 'rok', 'en': 'year'};
        this.onThisDay = {'pl': 'Tego dnia…', 'en': 'On this day…'};
        this.thisMonth = {'pl': 'Rok po roku…', 'en': 'Year by year…'};
        this.births = {'pl': 'Urodzili się', 'en': 'Births'};
        this.deaths = {'pl': 'Zmarli', 'en': 'Deaths'};
        this.badFilename = {'pl': 'nieobsługiwany tytuł pliku', 'en': 'unsupported note title'};
    }
}

class JournalYear {
    constructor(date) {
        let obj = moment(date);
        this.year = parseInt(obj.format("YYYY"));
        this.days = moment(this.year + "-12-31").dayOfYear();
        this.isLeap = obj.isLeapYear();
        this.dir = `${Journal.dir}/${this.year}`;
        this.path = `${this.dir}/${this.year}`;
        this.link = `[[${this.path}|${this.year}]]`;
    }
}

class JournalMonth {
    constructor(date) {
        let obj = moment(date);
        this.name = obj.locale(Journal.locale).format("MMMM");
        this.nameEn = obj.locale('en').format("MMMM");
        this.nameCap = this.name.cfl();
        this.nameGen = obj.locale(Journal.locale).format("LL").split(" ")[1];
        this.year = parseInt(obj.format("YYYY"));
        this.month = obj.format("MM");
        this.monthInt = parseInt(obj.format("M"));
        this.fullName = `${this.name} ${this.year}`;
        this.fullNameEn = `${this.nameEn} ${this.year}`;
        this.days = parseInt(obj.daysInMonth());
        this.firstDay = obj.startOf("month").format("YYYY-MM-DD");
        this.firstDayDow = moment(this.firstDay).isoWeekday();
        this.lastDay = obj.endOf("month").format("YYYY-MM-DD");
        this.lastDayNum = obj.endOf("month").format("DD");
        this.lastDayDow = moment(this.lastDay).isoWeekday();
        this.dir = `${Journal.dir}/${this.year}/${this.year}-${this.month}`;
        this.path = `${this.dir}/${this.year}-${this.month}`;
        this.link = `[[${this.path}|${this.name}]]`;
        this.linkC = `[[${this.path}|${this.name.cfl()}]]`;
        this.pathThisMonth = `${Journal.dir}/${this.month}/${this.month}`;
        this.linkThisMonth = `[[${this.pathThisMonth}|${this.name.cfl()}]]`;
        this.linkGen = `[[${this.path}|${this.nameGen}]]`;
    }
}

class JournalDay {
    constructor(date) {
        let obj = moment(date);
        this.name = obj.locale(Journal.locale).format("dddd");
        this.nameCap = this.name.cfl();
        this.nameEn = obj.locale('en').format("dddd");
        this.fullNameEn = obj.locale('en').format("D MMMM YYYY");
        this.fullNameEnAlt = obj.locale('en').format("MMMM D, YYYY");
        this.fullName = obj.locale(Journal.locale).format("LL");
        this.shortName = obj.locale(Journal.locale).format("dd").toLowerCase();
        this.date = obj.format("YYYY-MM-DD");
        this.year = parseInt(obj.format("YYYY"));
        this.month = obj.format("MM");
        this.day = obj.format("DD");
        this.dayInt = parseInt(obj.format("D"));
        this.dow = parseInt(obj.format("E"));
        this.doy = obj.dayOfYear();
        this.dir = `${Journal.dir}/${this.year}/${this.year}-${this.month}`;
        this.path = `${this.dir}/${this.date}`;
        this.link = `[[${this.path}|${this.date}]]`;
        this.linkName = `[[${this.path}|${this.name}]]`;
        this.pathThisDay = `${Journal.dir}/${this.month}/${this.month}-${this.day}`;
        this.linkThisDay = `[[${this.pathThisDay}|${this.dayInt}]]`;
        this.lifedays = obj.diff(moment(Journal.birthday, "YYYY-MM-DD"), "days") + 1;
        this.week = obj.isoWeek();
    }
}

class JournalThisDay {
    constructor(date) {
        let obj = moment(date);
        this.name = obj.locale(Journal.locale).format(Journal.formatThisDay);
        this.nameEn = obj.locale('en').format(Journal.formatThisDay);
        this.filename = obj.format("MM-DD");
        this.month = obj.format("MM");
        this.monthInt = parseInt(obj.format("M"));
        this.day = obj.format("DD");
        this.dayInt = parseInt(obj.format("D"));
        this.dir = `${Journal.dir}/${this.month}`;
        this.path = `${this.dir}/${this.filename}`;
        this.link = `[[${this.path}|${this.name}]]`;
        this.linkGen = `[[${this.path}|${this.name}]]`;
    }
}

class JournalThisMonth {
    constructor(month) {
        let obj = moment(month);
        this.month = obj.format("MM");
        this.monthInt = parseInt(obj.format("M"));
        this.name = obj.locale(Journal.locale).format("MMMM");
        this.nameEn = obj.locale("en").format("MMMM");
        this.nameCap = this.name.cfl();
        this.nameGen = obj.locale(Journal.locale).format("LL").split(" ")[1];
        this.dir = `${Journal.dir}/${this.month}`;
        this.path = `${this.dir}/${this.month}`;
        this.link = `[[${this.path}|${this.name}]]`;
        this.linkGen = `[[${this.path}|${this.nameGen}]]`;
    }
}

class Journal {
    static birthday = '1979-06-14';
    static locale = 'pl';
    static name = "Journal";
    static dir = 'Journal';
    static formatDateTime = 'YYYY-MM-DD HH:mm';
    static formatMonth = 'YYYY-MM';
    static formatDay = 'YYYY-MM-DD';
    static formatThisDay = 'D MMMM';
    static summary = "Summary";
    static summaryDay = "Tego dnia…";
    static summaryMonth = "Dzień po dniu…";
    static summaryYear = "Miesiąc po miesiącu…";

    constructor(filename) {
        this.dict = new JournalDictionary;
        this.name = Journal.name;
        this.default = {'year': '2024', 'month': '01', 'day': '01'};
        this.path = `${Journal.dir}/${this.name}`;
        this.link = `[[${this.path}|${this.name}]]`;
        this.filename = filename;
        this.locale = Journal.locale;
        this.symbol = {'cal': '🗓', 'left': '← ', 'right': ' →', 'sep': ' • '};
        this.kind = this.setKind(filename.length);
        this.tags = `journal/${this.kind}`;
        this.now = moment().local().format(Journal.formatDateTime);
        this.uuid = this.uuid();
        switch(this.kind) {
            case 'day':
                this.date = moment(filename);
                this.setDay();
                break;
            case 'month':
                this.date = moment(filename + "-" + this.default.day);
                this.setMonth();
                break;
            case 'thisDay':
                this.date = moment(this.default.year + "-" + filename);
                this.setThisDay();
                break;
            case 'thisMonth':
                this.date = moment(this.default.year + "-" + filename + "-" + this.default.day);
                this.setThisMonth();
                break;
            case 'year':
                this.date = moment(filename + "-" + this.default.month + "-" + this.default.day);
                this.setYear();
                break;
            default:
                console.log("unsupported note title");
        }
    }

    setKind(fileLength) {
        let fileKind = {
            2:  'thisMonth',  // 01
            4:  'year',       // 2024
            5:  'thisDay',    // 01-01
            7:  'month',      // 2024-01
            10: 'day'         // 2024-01-01
        };
        return fileKind[fileLength] ?? 'unknown';
    }

    makeYearCalendar() {
        moment.locale(Journal.locale);
        let calendar = `>[!info] ${this.thisYear.year}\n> `;
        for (let i = 1; i < 13; i++) {
            let m = i.toString().padStart(2, "0");
            let date = `${this.thisYear.year}-${m}-01`;
            let path = `${this.thisYear.path}-${m}/${this.thisYear.year}-${m}`;
            calendar += `[[${path}\\|${moment(date).format("MMMM")}]]`;
            (m < 12) ? calendar += this.symbol.sep : "";
        }
        return calendar;
    }
 
    makeMonthDays() {
        let days = {1: 31, 2: 29, 3: 31, 4: 30, 5: 31, 6: 30, 7: 31, 8: 31, 9: 30, 10: 31, 11: 30, 12: 31};
        let calendar = `>[!info] ${this.thisMonth.name}\n> `;
        for (let i = 1; i <= days[this.thisMonth.monthInt]; i++) {
            let m = i.toString().padStart(2, "0");
            let path = `${this.thisMonth.path}-${m}`;
            calendar += `[[${path}\\|${i}]]`;
            (m < days[this.thisMonth.monthInt]) ? calendar += this.symbol.sep : "";
        }
        return calendar;
    }
    
    makeMonthCalendar() {
        const nl = "\n";
        let calendar = "";
        for (let i = 1; i < 8; i++) {
            let dow = moment().locale(Journal.locale).isoWeekday(i).format("ddd").cfl();
            if (i == 7) dow +=  " |";
            calendar += (i == 7) ? "| " + dow : "| " + dow + " ";
        }
        calendar += nl + "| :-: | :-: | :-: | :-: | :-: | :-: | :-: |" + nl;
        for (let i = 1; i < this.thisMonth.firstDayDow; i++) {
            calendar += "|  .  ";
        }
        let dow = this.thisMonth.firstDayDow;

        for (let i = 1; i < this.thisMonth.days + 1; i++) {
            calendar += `| [[${this.thisMonth.dir}/${this.filename}-${i.toString().padStart(2, "0")}\\|${i}]] `;
            if (dow > 0 && dow % 7 === 0) {
                calendar += "|" + nl;
                dow = 1;
            } else {
                dow++;
            }
        }

        for (let i = this.thisMonth.lastDayDow; i < 7; i++) {
            calendar += "|  .  ";
        }
        if (dow != 1) {
            calendar += "|";
        }

        return calendar;
    }

    makeFmItems(obj) {
        let frontmatter = '';
        for (var key in obj) {
            frontmatter += `${key}: ${obj[key]}\n`;
        }
        return frontmatter.trim();
    }
    
    makeFmList(arr) {
        let list = '';
        arr.forEach(item => {list += `\n  - ${item}`});
        return list;
    }

    makeMdHeading(heading, level = 3) {
        let output = '';
        output = output.padStart(level, '#');
        return `${output} ${heading}\n`;
    }
    
    makeDataview(query) {
        let output = "```dataview\n";
        query.forEach(item => {output += `${item}\n`});
        output += "```\n";
        return output;
    }
    
    queryBirthdays(day, month) {
        return this.makeDataview([
            `LIST WITHOUT ID substring(file.frontmatter.birthdate, 0, 4) + ": " + file.link`,
            `FROM "People"`,
            `WHERE endswith(file.frontmatter.birthdate, "${month}-${day}")`,
            `SORT file.frontmatter.birthdate DESC`
        ]);
    }
    
    queryDeathdays(day, month) {
        return this.makeDataview([
            `LIST WITHOUT ID substring(file.frontmatter.deathdate, 0, 4) + ": " + file.link`,
            `FROM "People"`,
            `WHERE endswith(file.frontmatter.deathdate, "${month}-${day}")`,
            `SORT file.frontmatter.deathdate DESC`
        ]);
    }
    
    queryOnThisDay(day, month) {
        return this.makeDataview([
            `LIST WITHOUT ID link(file.name, string(year)) + ": " + summary`,
            `FROM "${Journal.dir}"`,
            `WHERE kind = "day" AND month = ${month} AND day = ${day}`,
            `SORT file.link DESC`
        ]);
    }

    queryYear(dir) {
        return this.makeDataview([
            `LIST WITHOUT ID link(file.name, string(monthname)) + ": " + summary`,
            `FROM "${dir}"`,
            `WHERE kind = "month"`,
            `SORT file.link DESC`
        ]);
    }
    
    queryMonth(dir) {
        return this.makeDataview([
            `LIST WITHOUT ID link(file.name, string(file.frontmatter.day)) + ": " + summary`,
            `FROM "${dir}"`,
            `WHERE kind = "day" AND summary > ""`,
            `SORT file.link DESC`
        ]);
    }
    
    queryOnThisMonth(month) {
        return this.makeDataview([
            `LIST WITHOUT ID link(file.name, string(file.frontmatter.year)) + ": " + summary`,
            `FROM "${Journal.dir}"`,
            `WHERE kind = "month" AND month = ${month}`,
            `SORT file.link DESC`
        ]);
    }

    setDay() {
        this.thisDay = new JournalDay(this.date);
        this.prevDay = new JournalDay(moment(this.date).subtract(1, "d"));
        this.nextDay = new JournalDay(moment(this.date).add(1, "d"));
        this.thisMonth = new JournalMonth(this.date);
        this.thisYear = new JournalYear(this.date);
        let frontmatter = {
            year: this.thisYear.year,
            month: this.thisMonth.monthInt,
            name: this.thisDay.name,
            shortname: this.thisDay.shortName,
            day: this.thisDay.dayInt,
            //dotw: this.thisDay.dow,
            dow: this.thisDay.dow,
            doy: this.thisDay.doy,
            week: this.thisDay.week,
            lifedays: this.thisDay.lifedays,
            prevday: this.prevDay.date,
            nextday: this.nextDay.date
        };
        this.frontmatter = this.makeFmItems(frontmatter);
        this.cssclasses = this.makeFmList(['file-journal', 'file-journal-day']);
        this.aliases = this.makeFmList([this.thisDay.fullName, this.thisDay.fullNameEn, this.thisDay.fullNameEnAlt]);
        this.nav = `${this.symbol.left}${this.prevDay.linkName}${this.symbol.sep}`;
        this.nav += `${this.nextDay.linkName}${this.symbol.right}`;
        this.title = `${this.thisDay.dayInt} ${this.thisMonth.nameGen} ${this.thisYear.year}`;
        this.header = `[[${Journal.dir}|${this.symbol.cal}]] [[${this.path}|${this.thisDay.name.cfl()}]], `;
        this.header += `${this.thisDay.linkThisDay} ${this.thisMonth.linkGen} ${this.thisYear.link}`;
        this.extra = "";
        this.dataview = "";
    }

    setMonth() {
        this.thisMonth = new JournalMonth(this.date);
        this.prevMonth = new JournalMonth(moment(this.date).subtract(1, "M"));
        this.nextMonth = new JournalMonth(moment(this.date).add(1, "M"));
        this.thisYear = new JournalYear(this.date);
        let frontmatter = {
            year: this.thisYear.year,
            month: this.thisMonth.monthInt,
            monthname: this.thisMonth.name,
            firstdotw: this.thisMonth.firstDayDow,
            lastdotw: this.thisMonth.lastDayDow,
            days: this.thisMonth.lastDayNum
        };
        this.frontmatter = this.makeFmItems(frontmatter);
        this.cssclasses = this.makeFmList(['file-journal', 'file-journal-month']);
        this.aliases = `[${this.thisMonth.fullName}, ${this.thisMonth.fullNameEn}]`;
        this.nav = `${this.symbol.left}${this.prevMonth.link}${this.symbol.sep}`;
        this.nav += `${this.nextMonth.link}${this.symbol.right}`;
        this.title = `${this.thisMonth.nameCap} ${this.thisYear.year}`;
        this.header = `[[${Journal.dir}|${this.symbol.cal}]] ${this.thisMonth.linkThisMonth} ${this.thisYear.link}`;
        this.extra = this.makeMonthCalendar();
        this.dataview = this.makeMdHeading(`${this.thisMonth.nameCap} ${this.dict.byDays[Journal.locale]}`);
        this.dataview += this.queryMonth(this.thisMonth.dir);
    }
      
    setYear() {
        this.thisYear = new JournalYear(this.date);
        this.prevYear = new JournalYear(moment(this.date).subtract(1, "Y"));
        this.nextYear = new JournalYear(moment(this.date).add(1, "Y"));
        let frontmatter = {
            year: this.thisYear.year,
            isleap: this.thisYear.isLeap
        };
        this.frontmatter = this.makeFmItems(frontmatter);
        this.cssclasses = this.makeFmList(['file-journal', 'file-journal-year']);
        this.aliases = `${this.dict.year.pl} ${this.thisYear.year}`;
        this.nav = `${this.symbol.left}${this.prevYear.link}${this.symbol.sep}`;
        this.nav += `${this.nextYear.link}${this.symbol.right}`;
        this.title = `${this.dict.year.pl.cfl()} ${this.thisYear.year}`;
        this.header = `[[${Journal.dir}|${this.symbol.cal}]] [[${Journal.dir}|${this.dict.year.pl.cfl()}]] ${this.thisYear.year}`;
        this.extra = this.makeYearCalendar();
        this.dataview = this.makeMdHeading(`${this.thisYear.year} ${this.dict.byMonth[Journal.locale]}`);
        this.dataview += this.queryYear(this.thisYear.dir);
    }

    setThisDay() {
        this.thisDay = new JournalThisDay(this.date);
        this.thisMonth = new JournalThisMonth(this.date);
        this.prevDay = new JournalThisDay(moment(this.date).subtract(1, "d"));
        this.nextDay = new JournalThisDay(moment(this.date).add(1, "d"));
        let frontmatter = {
            month: this.thisDay.monthInt,
            day: this.thisDay.dayInt
        };
        this.frontmatter = this.makeFmItems(frontmatter);
        this.aliases = this.makeFmList([`${this.thisDay.dayInt} ${this.thisMonth.nameGen}`, `${this.thisDay.dayInt} ${this.thisMonth.nameEn}`]);
        this.cssclasses = this.makeFmList(['file-journal', 'file-journal-thisday']);
        this.title = `${this.thisDay.dayInt} ${this.thisMonth.nameGen}`;
        this.header = `[[${Journal.dir}|${this.symbol.cal}]] [[${this.path}|${this.thisDay.dayInt}]] ${this.thisMonth.linkGen}`;
        this.nav = `${this.symbol.left}${this.prevDay.link}${this.symbol.sep}`;
        this.nav += `${this.nextDay.link}${this.symbol.right}`;
        this.extra = '';
        this.dataview = this.makeMdHeading(this.dict.onThisDay[Journal.locale]);
        this.dataview += this.queryOnThisDay(this.thisDay.dayInt, this.thisMonth.monthInt);
        this.dataview += this.makeMdHeading(this.dict.births[Journal.locale]);
        this.dataview += this.queryBirthdays(this.thisDay.dayInt, this.thisMonth.monthInt);
        this.dataview += this.makeMdHeading(this.dict.deaths[Journal.locale]);
        this.dataview += this.queryDeathdays(this.thisDay.dayInt, this.thisMonth.monthInt);
    }
    
    setThisMonth() {
        this.thisMonth = new JournalThisMonth(this.date);
        this.prevMonth = new JournalThisMonth(moment(this.date).subtract(1, "M"));
        this.nextMonth = new JournalThisMonth(moment(this.date).add(1, "M"));
        let frontmatter = {
            month: this.thisMonth.monthInt,
            monthname: this.thisMonth.name,
            genetivus: this.thisMonth.nameGen
        };
        this.frontmatter = this.makeFmItems(frontmatter);
        this.aliases = this.makeFmList([this.thisMonth.name, this.thisMonth.nameGen, this.thisMonth.nameEn]);
        this.cssclasses = this.makeFmList(['file-journal', 'file-journal-thismonth']);
        this.title = this.thisMonth.nameCap;
        this.header = `[[${Journal.dir}|${this.symbol.cal}]] [[${this.path}|${this.thisMonth.name.cfl()}]] (${this.thisMonth.nameEn})`;
        this.nav = `${this.symbol.left}${this.prevMonth.link}${this.symbol.sep}`;
        this.nav += `${this.nextMonth.link}${this.symbol.right}`;
        this.extra = this.makeMonthDays();
        this.dataview = this.makeMdHeading(this.dict.thisMonth[Journal.locale]);
        this.dataview += this.queryOnThisMonth(this.thisMonth.monthInt);
    }
    
    uuid() {
        var lut = []; for (var i=0; i<256; i++) { lut[i] = (i<16?'0':'')+(i).toString(16); }
        var d0 = Math.random()*0xffffffff|0; var d1 = Math.random()*0xffffffff|0;
        var d2 = Math.random()*0xffffffff|0; var d3 = Math.random()*0xffffffff|0;
        return lut[d0&0xff]+lut[d0>>8&0xff]+lut[d0>>16&0xff]+lut[d0>>24&0xff]+'-'+
        lut[d1&0xff]+lut[d1>>8&0xff]+'-'+lut[d1>>16&0x0f|0x40]+lut[d1>>24&0xff]+'-'+
        lut[d2&0x3f|0x80]+lut[d2>>8&0xff]+'-'+lut[d2>>16&0xff]+lut[d2>>24&0xff]+
        lut[d3&0xff]+lut[d3>>8&0xff]+lut[d3>>16&0xff]+lut[d3>>24&0xff];
    }
    
}

function makejournal(filename) {
    return new Journal(filename);
}

module.exports = makejournal;
