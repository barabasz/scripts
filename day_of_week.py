class Dow:
    """
    Calculation of the day of the week (DOW) for a given date
    taking into account the change of the Julian calendar
    to the Gregorian calendar introduced on October 15, 1582.
    The date must be in YYYY-MM-DD format.
    """
    def __init__(self, date: str):
        self.date: str = date
        self.dateList: list = date.split('-')
        self.year: int = int(self.dateList[0])
        self.month: int = int(self.dateList[1])
        self.day: int = int(self.dateList[2])
        self.isGregorian: bool = self.is_gregorian()
        self.yearNum: int = self.year % 100
        self.yearCode: int = self.get_year_code()
        self.century: int = self.year // 100
        self.centuryCode: int = self.get_century_code()
        self.isLeap: bool = self.is_leap_year()
        self.leapCode: int = 1 if self.isLeap else 0
        self.monthName: str = self.get_month_name()
        self.monthCode: int = self.get_month_code()
        self.dowCode: int = self.get_dow_code()
        self.dow: str = self.get_dow()
        self.dateLong: str = self.get_date_long()
        self.info: str = self.get_info()

    def is_gregorian(self) -> bool:
        if (self.year > 1582) \
            or (self.year == 1582 and self.month > 10) \
                or (self.year == 1582 and self.month == 10 and self.day >= 15):
            return True
        else:
            return False

    def get_year_code(self) -> int:
        return (self.yearNum + self.yearNum // 4) % 7

    def get_month_code(self) -> int:
        month_string = "033614625035"
        return int(month_string[self.month-1:self.month])

    def get_month_name(self) -> str:
        months = ["January", "February", "March", "April", "May", "June",
                  "July", "August", "September", "October", "November", "December"]
        return months[self.month-1]

    def get_century_code(self) -> int:
        century_string = "206420642064"
        if self.isGregorian:
            return int(century_string[self.century-14:self.century-13])
        else:
            return (11 - self.century) % 7

    def is_leap_year(self) -> bool:
        if (self.isGregorian and (self.year % 4 == 0 and self.year % 100 != 0) or (self.year % 400 == 0)) \
                or (not self.isGregorian and (self.year % 4 == 0)):
            return True
        else:
            return False

    def get_dow_code(self) -> int:
        return (self.yearCode + self.monthCode + self.centuryCode + self.day - self.leapCode) % 7

    def get_dow(self) -> str:
        days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        return days[self.dowCode]

    def get_date_long(self) -> str:
        return (f"{self.day} of {self.monthName} {self.year} is {self.dow} "
                f"({'Gregorian' if self.isGregorian else 'Julian'})")

    def get_info(self) -> str:
        return (f"codes: year = {self.yearCode}, month = {self.monthCode}, "
                f"century = {self.centuryCode}, leap = {self.leapCode}")


a = Dow("1410-07-15")
print(a.dateLong, "the Battle of Grunwald")
b = Dow('1582-10-04')
print(b.dateLong, "the last day of Julian calendar")
c = Dow('1582-10-15')
print(c.dateLong, "the first day of Gregorian calendar")
d = Dow('2023-05-05')
print(d.dateLong, "the end of the COVID-19 pandemic")
