class PersonInfo {

    name() {
        let output = '';
        let genders = {male: '♂', female: '♀'};
        output += this.fm.name ? `${this.fm.name} ` : '';
        output += this.fm.middlename ? `${this.fm.middlename} ` : '';
        output += this.fm.nickname ? `“${this.fm.nickname}” ` : '';
        output += this.fm.surname ? `${this.fm.surname} ` : '';
        output += (this.fm.maidenname && (this.fm.maidenname != this.fm.surname)) ? `(${this.fm.maidenname}) ` : '';
        output += (this.fm.persontag) ? `#${this.fm.persontag} ` : '';
        output += this.fm.sex ? `${genders[this.fm.sex]}` : '';
        return (output) ? output : this.title;
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

    queryJournal(tag) {
        return this.makeDataview([
            `LIST summary`,
            `FROM "Journal"`,
            `WHERE contains(tags, "${tag}") OR contains(this.file.inlinks, file.link)`,
            `SORT file.link ASC`
        ]);
    }

    queryBacklinks(tag) {
        return this.makeDataview([
            `LIST`,
            `WHERE contains(tags, "${tag}") OR contains(this.file.inlinks, file.link) AND type != "journal"`,
            `SORT file.name ASC`
        ]);
    }

    sayLata(age) {
        let lastone = parseInt(age.toString().slice(-1));
        let lasttwo = parseInt(age.toString().slice(-2));
        if (age == 1) {
            return 'rok';
        } else if (lastone > 1 && lastone <= 4) {
            return 'lata';
        } else if (age >= 5 && age <= 21) {
            return 'lat';
        } else if (lasttwo >= 10 && lasttwo <= 19) {
            return 'lat';
        } else if (lastone >= 2 && lastone <= 4) {
            return 'lata';
        } else {
            return 'lat';
        }
    }

    date(date, time, type) {
        date = moment(date).locale("pl");
        let dayname = date.format("LL").split(" ").slice(0, 2).join(" ");
        let daynums = date.format("MM-DD");
        let month = date.format("MM");
        let dayfile = `Journal/${month}/${daynums}`;
        let year = date.format("YYYY");
        let output = '';
        let daylink = ';'

        if (this.dv.page(daynums)) {
            daylink = this.dv.fileLink(daynums, false, dayname);
        } else {
            daylink = this.dv.fileLink(dayfile, false, dayname);
        }
        let yearlink = '';
        if (this.dv.page(year)) {
            yearlink = this.dv.fileLink(year, false, year);
        } else {
            yearlink = this.dv.fileLink(`Jounrnal/${year}/${year}`, false, year);
        }
        output += `${daylink} `;
        if (year != '1900') {
            output += `${yearlink} `;

            if (type == 'birthdate') {
                    output += this.fm.birthdate ? ` [[${this.zodiac().polish}|${this.zodiac().icon}]] ` : '';
            }

            let diff = moment().diff(date, 'years', false);
            if (!this.fm.deathdate) {
                output += `(${diff} ${this.sayLata(diff)})`;
            } else {
                output += `(${diff} ${this.sayLata(diff)} temu)`;
            }
        }
        output += (time) ? ` o ${time} ` : '';
        return output;
    }

    place(place) {
        let placeloc = '';
        let output = ' w ';
        if (this.dv.page(place)) {
            if (this.dv.page(place).file.frontmatter.locativus) {
                placeloc = this.dv.page(place).file.frontmatter.locativus;
            } 
            output += this.dv.fileLink(place, false, placeloc);
        } else {
            output += this.dv.fileLink(`Places/${place}`, false, place);
        }
        return output;
    }

    contact() {
        let output = '\n';
        let icons = {home: ':luc_home:', phone: ':luc_phone:', email: ':luc_mail:'}

        if (this.fm.address) {
            let mapsapi = 'https://www.google.com/maps/place?q=';
            let addressmod = this.fm.address.replace(/ /gi, "+");
            let addresslink = `[${this.fm.address}](${mapsapi}${addressmod})`;
            output += `${icons.home} ${addresslink} `;
        }
        output += (this.fm.phone || this.fm.email) ? '\n' : '';
        if (this.fm.phone) {
            //POPRAWIĆ!!!!
            let cleanphone = '+48602552794';
            //[+48 508 071 678](tel:+48508071678)
            let phonelink = `<a href="tel:${cleanphone}">${this.fm.phone}</a>`;
            output += `${icons.phone} ${phonelink} `;
        }
        output += (this.fm.email) ? `${icons.email} ${this.fm.email} ` : '';
        return output;
    }

    zodiac() {

        let date = moment(this.fm.birthdate);
        let day = date.format("D");
        let month = date.format("M");

        var signs = {
            ari: {house:  1, icon: '♈️', latin: 'Aries', english: 'Ram', polish: 'Baran'},
            tau: {house:  2, icon: '♉️', latin: 'Taurus', english: 'Bull', polish: 'Byk'},
            gem: {house:  3, icon: '♊️', latin: 'Gemini', english: 'Twins', polish: 'Bliźnięta'},
            can: {house:  4, icon: '♋️', latin: 'Cancer', english: 'Crab', polish: 'Rak'},
            leo: {house:  5, icon: '♌️', latin: 'Leo', english: 'Lion', polish: 'lew'},
            vir: {house:  6, icon: '♍️', latin: 'Virgo', english: 'Maiden', polish: 'Panna'},
            lib: {house:  7, icon: '♎️', latin: 'Libra', english: 'Scales', polish: 'Waga'},
            sco: {house:  8, icon: '♏️', latin: 'Scorpio', english: 'Scorpion', polish: 'Skorpion'},
            sag: {house:  9, icon: '♐️', latin: 'Sagittarius', english: 'Archer', polish: 'Strzelec'},
            cap: {house: 10, icon: '♑️', latin: 'Capricorn', english: 'Goat', polish: 'Koziorożec'},
            aqu: {house: 11, icon: '♒️', latin: 'Aquarius', english: 'Water-Bearer', polish: 'Wodnik'},
            pis: {house: 12, icon: '♓️', latin: 'Pisces', english: 'Fish', polish: 'Ryby'},
        }

        if ((month == 1 && day <= 19) || (month == 12 && day >= 22)) {
            return signs.cap;
        } else if ((month == 1 && day >= 20) || (month == 2 && day <= 18)) {
            return signs.aqu;
        } else if ((month == 2 && day >= 19) || (month == 3 && day <= 20)) {
            return signs.pis;
        } else if ((month == 3 && day >= 21) || (month == 4 && day <= 19)) {
            return signs.ari;
        } else if ((month == 4 && day >= 20) || (month == 5 && day <= 20)) {
            return signs.tau;
        } else if ((month == 5 && day >= 21) || (month == 6 && day <= 20)) {
            return signs.gem;
        } else if ((month == 6 && day >= 21) || (month == 7 && day <= 22)) {
            return signs.can;
        } else if ((month == 7 && day >= 23) || (month == 8 && day <= 22)) {
            return signs.leo;
        } else if ((month == 8 && day >= 23) || (month == 9 && day <= 22)) {
            return signs.vir;
        } else if ((month == 9 && day >= 23) || (month == 10 && day <= 22)) {
            return signs.lib;
        } else if ((month == 10 && day >= 23) || (month == 11 && day <= 21)) {
            return signs.sco;
        } else if ((month == 11 && day >= 22) || (month == 12 && day <= 21)) {
            return signs.sag;
        }
    }

    docs() {
        let output = '';
        if (this.fm.pesel || this.fm.idcard || this.fm.passport) {
            output += (this.fm.pesel) ? `PESEL: \`${this.fm.pesel}\`` : '';
            output += (this.fm.pesel && this.fm.idcard) ? ', nr dowodu: ': '';
            output += (!this.fm.pesel && this.fm.idcard) ? 'Nr dowodu: ': '';
            output += (this.fm.idcard) ? `\`${this.fm.idcard}\`` : '';
            output += ((this.fm.pesel || this.fm.idcard) && this.fm.passport) ? ', paszport: ': '';
            output += (!this.fm.pesel && !this.fm.idcard && this.fm.passport) ? 'Paszport: ': '';
            output += (this.fm.passport) ? `\`${this.fm.passport}\`` : '';
            return output + '.';
        } else {
            return '';
        }
    }

    socials() {
        if (this.fm.website || this.fm.github || this.fm.linkedin || 
            this.fm.twittter || this.fm.facebook || this.fm.instagram) {
            let output = '\n';
            let icons = {
                facebook: ':luc_facebook:',
                linkedin: ':luc_linkedin:',
                twitter: ':luc_twitter:',
                instagram: ':luc_instagram:',
                github: ':luc_github:',
                website: ':luc_globe:',
            };
            output += (this.fm.website) ? `${icons.website} [website](${this.fm.website}) ` : '';
            output += (this.fm.github) ? `${icons.github} [github](${this.fm.github}) ` : '';
            output += (this.fm.linkedin) ? `${icons.linkedin} [linkedin](${this.fm.linkedin}) ` : '';
            output += (this.fm.twittter) ? `${icons.twittter} [twittter](${this.fm.twittter}) ` : '';
            output += (this.fm.facebook) ? `${icons.facebook} [facebook](${this.fm.facebook}) ` : '';
            output += (this.fm.instagram) ? `${icons.instagram} [instagram](${this.fm.instagram}) ` : '';
            return output;
        } else {
            return '';
        }

    }

    birth() {
        let output = '';
        if (this.fm.birthdate || this.fm.birthyear || this.fm.birthplace) {
            output += ', ur. ';
            output += (this.fm.birthdate) ? this.date(this.fm.birthdate, this.fm.birthtime, 'birthdate') : '';
            output += (!this.fm.birthdate && this.fm.birthyear) ? `[[Journal/${this.fm.birthyear}/${this.fm.birthyear}|${this.fm.birthyear}]]` : '';
            output += (this.fm.birthplace) ? this.place(this.fm.birthplace) : '';
            output += (this.fm.deathdate || this.fm.deathyear || this.fm.deathplace || this.fm.nameday) ? '' : '. ';
        }
        return output;
    }

    death() {
        let output = '';
        if (this.fm.deathdate || this.fm.deathyear || this.fm.deathplace) {
            output += (this.fm.deathdate || this.fm.deathplace) ? ', zm. ' : '';
            output += (this.fm.deathdate) ? this.date(this.fm.deathdate, this.fm.deathtime) : '';
            output += (!this.fm.deathdate && this.fm.deathyear) ? `[[Journal/${this.fm.deathyear}/${this.fm.deathyear}|${this.fm.deathyear}]]` : '';
            output += (this.fm.deathplace) ? this.place(this.fm.deathplace) : '';
            output += (this.fm.deathcause) ? ` (${this.fm.deathcause})` : '';
            output += (this.fm.nameday) ? '' : '. ';
            return output;
        } else {
            return '';
        }
    }

    nameday() {
        let output = '';
        if (this.fm.nameday) {
            let pseudodate = `2000-${this.fm.nameday}`;
            let date = moment(pseudodate).locale("pl");
            let month = date.format("MM");
            let daynums = date.format("MM-DD");
            let dayname = date.format("LL").split(" ").slice(0, 2).join(" ");
            let dayfile = `Journal/${month}/${daynums}`;
            let daylink = '';
            if (this.dv.page(daynums)) {
                daylink = this.dv.fileLink(daynums, false, dayname);
            } else {
                daylink = this.dv.fileLink(dayfile, false, dayname);
            }
            output += `, im. ${daylink}. `;
        }
        return output;
    }

    journal(tag) {
        let output = '';
        output += this.makeMdHeading("Journal");
        output += this.queryJournal(tag);
        return output;
    }

    backlinks() {
        let output = '';
        output += this.makeMdHeading("Backlinks");
        output += this.queryBacklinks();
        return output;
    }

    printInfo(dv) {
        this.dv = dv;
        this.fm =  dv.current().file.frontmatter;
        this.title = dv.current().file.name;
        this.output = `**${this.name()}**`;
        this.output += this.birth();
        this.output += this.death();
        this.output += this.nameday();
        this.output += this.docs();
        this.output += (this.fm.address ||this.fm.phone || this.fm.email) ? this.contact() : '';
        this.output += this.socials();
        this.dv.el("div", this.output, { cls: "person-file-info" });
    }

    printDataview(dv) {
        this.dv = dv;
        this.fm =  dv.current().file.frontmatter;
        this.title = dv.current().file.name;
        this.output = this.journal(this.fm.persontag);
        this.output += this.backlinks(this.fm.persontag);
        this.dv.el("div", this.output, { cls: "person-file-info" });
    }

}
