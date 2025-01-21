class JournalInfo {

    cfl(string) {
        return string.charAt(0).toUpperCase() + string.slice(1);
    };

    defaults(dv) {
        this.root = 'Journal';
        this.locale = 'pl';
        this.dv = dv;
        this.fm =  dv.current().file.frontmatter;
        this.title = dv.current().file.name;
        this.kind = this.setKind();
        this.default = {year: '2024', month: '01', day: '01', sort: 'ASC'};
        this.symbol = {'cal': '🗓', 'left': '← ', 'right': ' →', 'sep': ' • '};
    }

    sayWpisy(count) {
        let lastone = parseInt(count.toString().slice(-1));
        let lasttwo = parseInt(count.toString().slice(-2));
        if (count == 1) {
            return 'wpis';
        } else if (lastone > 1 && lastone <= 4) {
            return 'wpisy';
        } else if (count >= 5 && count <= 21) {
            return 'wpisów';
        } else if (lasttwo >= 10 && lasttwo <= 19) {
            return 'wpisów';
        } else if (lastone >= 2 && lastone <= 4) {
            return 'wpisy';
        } else {
            return 'wpisów';
        }
    }

    setKind() {
        if (this.title == "Journal") {
            return 'journal';
        } else {
            let fileKind = {
                2:  'thisMonth',  // 01         -> days of month 
                4:  'year',       // 2024       -> months of this year
                5:  'thisDay',    // 01-01      -> on this day info
                7:  'month',      // 2024-01    -> this month calendar
                10: 'day'         // 2024-01-01 -> this day info
            };
            return fileKind[this.title.length] ?? 'unknown';
        }
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

    isHoliday(year, month, day) {
        let dayFileYear  = `${this.root}/${year}/${year}-${month}/${year}-${month}-${day}`;
        let dayFileMonth = `${this.root}/${month}/${month}-${day}`;
        let holiday = '';
        let holidays = [];
        if (this.dv.page(dayFileMonth) && this.dv.page(dayFileMonth).holiday) {
            holidays.push(this.dv.page(dayFileMonth).holiday);
        }
        if (this.dv.page(dayFileYear) && this.dv.page(dayFileYear).holiday) {
            if (!holidays[0] || holidays[0] != this.dv.page(dayFileYear).holiday) {
                holidays.push(this.dv.page(dayFileYear).holiday);
            }
        }
        return (holidays.length > 0) ? holidays : false;
    }

    makeMonthCalendar() {
        const year = this.fm.year;
        const month = this.fm.month.toString().padStart(2, "0");
        const firstDay = this.date.startOf("month").format("YYYY-MM-DD");
        const lastDay = this.date.endOf("month").format("YYYY-MM-DD");
        const firstDayDow = moment(firstDay).isoWeekday();
        const lastDayDow = moment(lastDay).isoWeekday();
        let calendar = "";
        let path = "";
        let day = '';
        let file = '';
        let link = '';

        calendar = '<table class="file-journal-month-calendar"><tr>';
        for (let i = 1; i < 8; i++) {
            let dow = this.cfl(moment().locale('pl').isoWeekday(i).format("ddd"));
            calendar += `<th>${dow}</th>`;
        }
        calendar += "</tr><tr>";
        
        for (let i = 1; i < firstDayDow; i++) {
            calendar += "<td></td>";
        }
        let dow = firstDayDow;

        for (let i = 1; i < this.fm.days + 1; i++) {
            day = i.toString().padStart(2, "0");
            file = `${year}-${month}-${day}`;
            path = `${this.root}/${year}/${year}-${month}/`;
            if (this.dv.page(file)) {
                link = `<span class="cm-strong"><a href="${file}.md" class="internal-link">${i}</a></span>`;
            } else {
                link = `<a href="${path+file}.md" class="internal-link is-unresolved">${i}</a>`;
            }
            if (this.isHoliday(month, day) || this.isHoliday(year, month, day) || dow == 7) {
                calendar += `<td class="holiday">${link}</td>`;
            } else {
                calendar += `<td>${link}</td>`;
            }
            if (dow > 0 && dow % 7 === 0) {
                calendar += "</tr><tr>";
                dow = 1;
            } else {
                dow++;
            }
        }

        for (let i = lastDayDow; i < 7; i++) {
            calendar += "<td></td>";
        }
        calendar += "</tr></table>"
        return calendar;
    }

    queryYearHolidays(year) {
        return this.makeDataview([
            `LIST WITHOUT ID link(file.name, padleft(string(month), 2, "0") + "-" + padleft(string(day), 2, "0")) + ": " + holiday`,
            `FROM "Journal/${year}"`,
            `WHERE holiday`,
            `FLATTEN month as month`,
            `SORT file.name ${this.default.sort}`
        ]);
    }

    queryHolidays(month) {
        return this.makeDataview([
            `LIST WITHOUT ID link(file.name, string(day)) + ": " +`,
                `choice(holiday, "<span class='red cm-strong'>" + holiday + "</span>", "") + `,
                `choice(holiday AND celebration, ", ", "") +`,
                `choice(celebration, celebration, "")`,
            `FROM "${this.root}/${month}"`,
            `WHERE holiday > "" OR celebration > ""`,
            `SORT file.link ${this.default.sort}`
        ]);
    }

    queryBirthdays(day, month) {
        return this.makeDataview([
            `LIST WITHOUT ID choice(birthdate.year = 1900,
                file.link, link(string(birthdate.year)) + ": " + file.link)`,
            `FROM "People"`,
            `WHERE birthdate.month = ${month} AND birthdate.day = ${day}`,
            `SORT birthdate ${this.default.sort}`
        ]);
    }

    queryBirthdaysYear(year) {
        return this.makeDataview([
            `LIST WITHOUT ID link(
                string(birthdate.year) +
                    "-" + padleft(string(birthdate.month), 2, "0") + 
                    "-" + padleft(string(birthdate.day), 2, "0"), 
                padleft(string(birthdate.month), 2, "0") + 
                    "-" + padleft(string(birthdate.day), 2, "0")) + 
                ": " + file.link + choice(maidenname, " (" + maidenname + ")", "")`,
            `FROM "People"`,
            `WHERE birthdate.year = ${year}`,
            `SORT birthdate ${this.default.sort}`
        ]);
    }

    queryDeathdays(day, month) {
        return this.makeDataview([
            `LIST WITHOUT ID link(string(deathdate.year)) + ": " + file.link`,
            `FROM "People"`,
            `WHERE deathdate.month = ${month} AND deathdate.day = ${day}`,
            `SORT deathdate ${this.default.sort}`
        ]);
    }

    queryDeathdaysYear(year) {
        return this.makeDataview([
            `LIST WITHOUT ID link(
                string(deathdate.year) +
                    "-" + padleft(string(deathdate.month), 2, "0") + 
                    "-" + padleft(string(deathdate.day), 2, "0"), 
                padleft(string(deathdate.month), 2, "0") + 
                    "-" + padleft(string(deathdate.day), 2, "0")) + 
                ": " + file.link + choice(maidenname, " (" + maidenname + ")", "")`,
            `FROM "People"`,
            `WHERE deathdate.year = ${year}`,
            `SORT deathdate ${this.default.sort}`
        ]);
    }

    queryOnThisDay(day, month) {
        return this.makeDataview([
            `LIST WITHOUT ID link(file.name, string(year)) + ": " + summary`,
            `FROM "${this.root}"`,
            `WHERE kind = "day" AND month = ${month} AND day = ${day}`,
            `SORT file.link ${this.default.sort}`
        ]);
    }

    queryJournal() {
        return this.makeDataview([
            `LIST WITHOUT ID file.link + ": " + summary`,
            `FROM "${this.root}"`,
            `WHERE kind = "year"`,
            `SORT file.link ${this.default.sort}`
        ]);
    }

    queryYear(year) {
        return this.makeDataview([
            `LIST WITHOUT ID link(file.name, string(monthname)) + ": " + summary`,
            `FROM "${this.root}/${year}"`,
            `WHERE kind = "month" AND summary > ""`,
            `SORT file.link ${this.default.sort}`
        ]);
    }
    
    queryMonth() {
        let month = this.date.format("MM");
        let dir = `${this.root}/${this.fm.year}/${this.fm.year}-${month}`;
        return this.makeDataview([
            `LIST WITHOUT ID "**" + link(file.name, string(file.frontmatter.day)) + "** (" + file.frontmatter.shortname +"): " + summary`,
            `FROM "${dir}"`,
            `WHERE kind = "day" AND summary > ""`,
            `SORT file.link ${this.default.sort}`
        ]);
    }
    
    queryOnThisMonth() {
        let month = this.fm.month;
        return this.makeDataview([
            `LIST WITHOUT ID link(file.name, string(file.frontmatter.year)) + ": " + summary`,
            `FROM "${this.root}"`,
            `WHERE kind = "month" AND month = ${month}`,
            `SORT file.link ${this.default.sort}`
        ]);
    }

    setJournalInfo() {
        let output = '';
        let year = this.date.format("YYYY");
        let path = `${this.root}`;

        output += '**Wpisy wg lat**: ';
        let yearPages = this.dv.pages('"Journal"').where(p => p.kind == "year").sort(p => p.file.name, "asc").file.name;
        let yearFirst = yearPages[0];
        let yearLast = yearPages[yearPages.length-1];
        for (let y = yearFirst; y <= yearLast; y++) {
            let pages = this.dv.pages(`"${path}/${y}"`).where(p => p.kind == "day").length;
            // ----

            //if (this.dv.page(file)) {
            //    link = `<span class="cm-strong"><a href="${file}.md" class="internal-link">${i}</a><span>`;
            //} else {
            //    link = `<span class="is-unresolved"><a href="${path+file}.md">${i}</a></span>`;
            //}



            output += `[[${path}/${y}/${y}\\|${y}]]`;
            output += (pages > 0) ? ` (${pages})` : '';
            (y < yearLast) ? output += this.symbol.sep : "";
        }

        output += '\n\n\n**Wpisy wg miesięcy**: ';
        moment.locale(this.locale);
        for (let i = 1; i < 13; i++) {
            let m = i.toString().padStart(2, "0");
            let date = `${year}-${m}-${this.default.day}`;
            let pages = this.dv.pages(`"${path}"`).where(p => p.kind == "day" && p.month == i).length;
            output += `[[${path}/${m}/${m}\\|${moment(date).format("MMMM")}]]`;
            output += (pages > 0) ? ` (${pages})` : '';
            (m < 12) ? output += this.symbol.sep : "";
        }

        return output;
    }

    setJournalDataview() {
        let output = '';
        output += this.makeMdHeading("Rok po roku");
        output += this.queryJournal();
        return output;
    }

    getWeather() {
        let output = '';

        let tempminmax = ''
        if (this.fm.tempmin && this.fm.tempmax) {
            tempminmax += `${this.fm.tempmin}-${this.fm.tempmax}°C`;
        } else if (this.fm.tempmin) {
            tempminmax += `min ${this.fm.tempmin}°C`;
        } else if (this.fm.tempmax) {
            tempminmax += `max ${this.fm.tempmax}°C`;
        }

        if (this.fm.temp) {
            output += `🌡 ${this.fm.temp}°C`;
            output += tempminmax ? ` (${tempminmax})` : '';
        } else if (tempminmax) {
            output += `🌡 ${tempminmax}`;
        }

        output += (output && this.fm.wind) ? ' • ' : '';
        if (this.fm.wind) {
            output += `༄ ${this.fm.wind} ㎞/h`;
        }

        return output == '' ? '' : output + "\n";
    }

    getSunData() {
        let output = '';
        if (this.fm.sunrise || this.fm.sunmax || this.fm.sunset) {
            output += `🌞︎︎ ↗ ${this.fm.sunrise} ⋂ ${this.fm.sunmax} ↘ ${this.fm.sunset}`;
        }
        return output == '' ? '' : output + "\n";
    }

    getMoonData() {
        let output = '';
        if (this.fm.moonface || this.fm.sunrise || this.fm.sunmax || this.fm.sunset) {
            output += `🌒︎ ${this.fm.moonface}%↑ `;
            output += `↗ ${this.fm.moonrise} ⋂ ${this.fm.moonmax} ↘ ${this.fm.moonset}`;
        }
        return output == '' ? '' : output + "\n";
    }


    // Informacja o tym dniu (święta, który dzień w roku, słońce, księżyc, święta, itd.
    setDayInfo() {
        let output = '';
        let year = this.date.format("YYYY");
        let month = this.date.format("MM");
        let day = this.date.format("DD");

        output += this.getWeather();
        output += this.getSunData();
        output += this.getMoonData();

        if (this.isHoliday(year, month, day)) {
            output += '<span class="holiday">';
            output += this.isHoliday(year, month, day).join('</span>, <span class="holiday">');
            output += '</span>, ';
        }

        let doy = this.fm.doy ? this.fm.doy : this.date.dayOfYear();
        output += `${doy} dzień roku `;

        let week = this.fm.week ? this.fm.week : this.date.isoWeek();
        output += `(${week} tydzień), `;

        output += (this.fm.lifedays) ? `${this.fm.lifedays}\. dzień życia` : '';

        return output;
    }

    setDayDataview() {
        let output = '';
        output += 'Day dataview';
        return output;
    }

    setMonthInfo() {
        let output = '';
        output += this.makeMonthCalendar();
        return output;
    }

    setMonthDataview() {
        let output = '';
        output += this.makeMdHeading(`${this.cfl(this.date.locale('pl').format("MMMM"))} dzień po dniu`);
        output += this.queryMonth();
        return output;
    }

    setYearInfo() {
        let output = '';
        let year = this.date.format("YYYY");
        let path = `${this.root}/${year}/${year}`;

        let allpages = this.dv.pages(`"${this.root}/${year}"`).where(p => p.kind == "day").length;
        output += `**${allpages} ${this.sayWpisy(allpages)}**: `;

        moment.locale(this.locale);
        for (let i = 1; i < 13; i++) {
            let m = i.toString().padStart(2, "0");
            let date = `${year}-${m}-${this.default.day}`;
            let pages = this.dv.pages(`"${path}-${m}"`).where(p => p.kind == "day").length;
            output += `[[${path}-${m}/${year}-${m}\\|${moment(date).format("MMMM")}]]`;
            output += (pages > 0) ? ` (${pages})` : '';
            (m < 12) ? output += this.symbol.sep : "";
        }
        return output;
    }

    countYearHolidays() {
        let year = this.date.format("YYYY");
        return this.dv.pages('"Journal/' + year + '"').where(p => p["holiday"]).length;
    }

    countDeathdates() {
        let year = this.date.format("YYYY");
        return this.dv.pages(`"People"`).where(p => p.deathdate && p.deathdate.year == year).length;
    }

    countBirthdates() {
        let year = this.date.format("YYYY");
        return this.dv.pages(`"People"`).where(p => p.birthdate && p.birthdate.year == year).length;
    }

    countMonthSummaries() {
        let year = this.date.format("YYYY");
        return this.dv.pages('"Journal/' + year + '"').where(p => p["summary"] && p["kind"] == 'month').length;
    }

    setYearDataview() {
        let output = '';
        let year = this.date.format("YYYY");
        let holidays = this.countYearHolidays();
        if (holidays > 0) {
            output += this.makeMdHeading('Święta wolne od pracy (' + this.countYearHolidays() + ')');
            output += this.queryYearHolidays(year);
        }
        let summaries = this.countMonthSummaries();
        if (summaries > 0) {
            output += this.makeMdHeading('Miesiącami');
            output += this.queryYear(year);
        }
        let births = this.countBirthdates();
        if (births > 0) {
            output += this.makeMdHeading("Urodzili się (" + births + ")");
            output += this.queryBirthdaysYear(year);
        }
        let deaths = this.countDeathdates();
        if (deaths > 0) {
            output += this.makeMdHeading("Zmarli (" + deaths + ")");
            output += this.queryDeathdaysYear(year);
        }
        return (output != '') ? output : "brak danych do wyświetlenia";
    }

    setThisDayInfo() {
        let output = '';
        output += 'Rodzaj: ' + this.kind + ', data: ' + this.date.format("YYYY-MM-DD") + "\n";
        output += 'CSS: ' + this.css + "\n";
        output += 'Informacja o tym dniu (święta)';
        return output;
    }

    setThisDayDataview() {
        let output = '';
        let dayInt = parseInt(this.date.format("D"));
        let monthInt = parseInt(this.date.format("M"));
        output += this.makeMdHeading("Tego dnia");
        output += this.queryOnThisDay(dayInt, monthInt);

        if (this.dv.pages(`"People"`).where(p => p.birthdate && p.birthdate.month == monthInt && p.birthdate.day == dayInt).length > 0) {
            output += this.makeMdHeading("Urodzili się");
            output += this.queryBirthdays(dayInt, monthInt);
        };

        if (this.dv.pages(`"People"`).where(p => p.deathdate && p.deathdate.month == monthInt && p.deathdate.day == dayInt).length > 0) {
            output += this.makeMdHeading("Zmarli");
            output += this.queryDeathdays(dayInt, monthInt);
        };


        return output;
    }

    setThisMonthInfo() {
        let output = '';
        let month = this.date.format("MM");
        let monthInt = parseInt(month);
        let path = `${this.root}/${month}/${month}`;
        let days = {1: 31, 2: 29, 3: 31, 4: 30, 5: 31, 6: 30, 7: 31, 8: 31, 9: 30, 10: 31, 11: 30, 12: 31};
        for (let i = 1; i <= days[monthInt]; i++) {
            let m = i.toString().padStart(2, "0");
            let pages = this.dv.pages(`"${this.root}"`).where(p => p.kind == "day" && p.month == monthInt && p.day == i).length;
            if (this.dv.page(`${path}-${m}`)) {
                output += `<span class="cm-strong"><a href="${path}-${m}.md" class="internal-link">${i}</a></span>`;
            } else {
                output += `<a href="${path}-${m}.md" class="internal-link is-unresolved">${i}</a>`;
            }
            output += (pages > 0) ? ` (${pages})` : '';
            (m < days[monthInt]) ? output += this.symbol.sep : "";
        }
        return output;
    }

    setThisMonthDataview() {
        let output = '';
        output += this.makeMdHeading(`Stałe święta`);
        output += this.queryHolidays(this.date.format("MM"));
        output += this.makeMdHeading(`${this.cfl(this.date.locale('pl').format("MMMM"))} rok po roku`);
        output += this.queryOnThisMonth();
        return output;
    }

    printInfo(dv) {
        this.defaults(dv);
        this.css = 'file-journal-info';
        switch(this.kind) {
            case 'day':
                this.date = moment(this.title);
                this.output = this.setDayInfo();
                break;
            case 'month':
                this.date = moment(this.title + "-" + this.default.day);
                this.output = this.setMonthInfo();
                break;
            case 'thisDay':
                this.date = moment(this.default.year + "-" + this.title);
                this.output = this.setThisDayInfo();
                break;
            case 'thisMonth':
                this.date = moment(this.default.year + "-" + this.title + "-" + this.default.day);
                this.output = this.setThisMonthInfo();
                break;
            case 'year':
                this.date = moment(this.title + "-" + this.default.month + "-" + this.default.day);
                this.output = this.setYearInfo();
                break;
            case 'journal':
                this.date = moment(this.title + "-" + this.default.month + "-" + this.default.day);
                this.output = this.setJournalInfo();
                break;
            default:
                this.output = "printInfo: Unsupported note title: " + this.title;
                console.log("printInfo: Unsupported note title: " + this.title);
        }
        this.dv.el("div", this.output, { cls: this.css });
    }

    printDataview(dv) {
        this.defaults(dv);
        this.css = 'file-journal-dataview';

        switch(this.kind) {
            case 'day':
                this.date = moment(this.title);
                this.output = this.setDayDataview();
                break;
            case 'month':
                this.date = moment(this.title + "-" + this.default.day);
                this.output = this.setMonthDataview();
                break;
            case 'thisDay':
                this.date = moment(this.default.year + "-" + this.title);
                this.output = this.setThisDayDataview();
                break;
            case 'thisMonth':
                this.date = moment(this.default.year + "-" + this.title + "-" + this.default.day);
                this.output = this.setThisMonthDataview();
                break;
            case 'year':
                this.date = moment(this.title + "-" + this.default.month + "-" + this.default.day);
                this.output = this.setYearDataview();
                break;
            case 'journal':
                this.date = moment(this.title + "-" + this.default.month + "-" + this.default.day);
                this.output = this.setJournalDataview();
                break;
            default:
                this.output = "printDataview: Unsupported note title: " + this.title;
                console.log("printDataview: Unsupported note title: " + this.title);
        }

        this.dv.el("div", this.output, { cls: this.css });
    }

}
