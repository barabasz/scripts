"""
day_of_week.py — Day of the Week calculator for historical and modern dates.

Supports dates in ISO 8601 format (YYYY-MM-DD) in the range 0001-01-01 to 9999-12-31.
Handles the transition from the Julian to the Gregorian calendar introduced on
October 15, 1582. Dates October 5–14, 1582 do not exist in either calendar system
and are rejected. All dates before October 15, 1582 are treated as Julian;
dates from October 15, 1582 onwards are treated as Gregorian.
"""

import re
from datetime import date as _date


class Dow:
    """
    Calculates the day of the week (DOW) for a given historical or modern date.

    The main formula: (year_code + month_code + century_code + day - leap_code) mod 7

    Usage:
        d = Dow("1492-10-12")
        print(d.date_long)  # -> 12 of October 1492 was Friday (Julian)
        print(d.info)       # -> codes: year = 3, month = 0, century = 4, leap = 0
    """

    # Days per month in a non-leap year; index 0 unused (months are 1-based).
    _DAYS_IN_MONTH = (0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31)

    # Full English month names, 0-based (January = index 0).
    _MONTH_NAMES = (
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December",
    )

    # Full English day names, 0-based (Sunday = index 0).
    _DAY_NAMES = (
        "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday",
    )

    # DOW formula month offsets, 0-based (January = index 0).
    _MONTH_CODES = (0, 3, 3, 6, 1, 4, 6, 2, 5, 0, 3, 5)

    # DOW formula century offsets for the Gregorian calendar, cycling every 400 years.
    # Index 0 corresponds to the 15th century (1500s); pattern repeats as (0, 6, 4, 2).
    _GREGORIAN_CENTURY_CODES = (0, 6, 4, 2)

    def __init__(self, date_str: str):
        # Validate format before attempting to parse.
        if not re.fullmatch(r'\d{4}-\d{2}-\d{2}', date_str):
            raise ValueError(
                f"Invalid format: '{date_str}'. Expected YYYY-MM-DD "
                f"with zero-padded month and day (e.g. '0753-03-07')."
            )
        self.date = date_str
        parts = date_str.split('-')
        self.year: int = int(parts[0])
        self.month: int = int(parts[1])
        self.day: int = int(parts[2])
        self._validate()

    # ------------------------------------------------------------------
    # Private helpers
    # ------------------------------------------------------------------

    def _max_day(self) -> int:
        # Returns the maximum valid day number for the current month and year.
        if self.month == 2:
            return 29 if self.is_leap_year else 28
        return self._DAYS_IN_MONTH[self.month]

    def _validate(self) -> None:
        # Validates date components; raises ValueError for invalid or non-existent dates.
        if self.year < 1:
            raise ValueError(
                f"Year {self.year:04d} is out of range. "
                f"Minimum supported date is 0001-01-01."
            )
        if not 1 <= self.month <= 12:
            raise ValueError(
                f"Month {self.month:02d} is out of range (01-12)."
            )
        max_day = self._max_day()
        if not 1 <= self.day <= max_day:
            cal = 'Gregorian' if self.is_gregorian else 'Julian'
            raise ValueError(
                f"Day {self.day:02d} is out of range for {self.month_name} {self.year} "
                f"({cal} calendar): valid range is 01-{max_day:02d}."
            )
        if self.year == 1582 and self.month == 10 and 5 <= self.day <= 14:
            raise ValueError(
                f"Date {self.date} does not exist: October 5-14, 1582 were skipped "
                f"during the transition from the Julian to the Gregorian calendar."
            )

    # ------------------------------------------------------------------
    # Calendar system
    # ------------------------------------------------------------------

    @property
    def is_gregorian(self) -> bool:
        # Returns True if the date falls under the Gregorian calendar (on or after Oct 15, 1582).
        if self.year > 1582:
            return True
        if self.year == 1582:
            if self.month > 10:
                return True
            if self.month == 10 and self.day >= 15:
                return True
        return False

    @property
    def is_leap_year(self) -> bool:
        # Gregorian: divisible by 4, except centuries unless also divisible by 400.
        # Julian: every year divisible by 4.
        if self.is_gregorian:
            return (self.year % 4 == 0 and self.year % 100 != 0) or (self.year % 400 == 0)
        return self.year % 4 == 0

    # ------------------------------------------------------------------
    # DOW formula components
    # ------------------------------------------------------------------

    @property
    def year_num(self) -> int:
        # Last two digits of the year (0-99), used in the year code calculation.
        return self.year % 100

    @property
    def century(self) -> int:
        # Century number, e.g. 20 for years 2000-2099.
        return self.year // 100

    @property
    def year_code(self) -> int:
        # Encodes the position of the year within its century for the DOW formula.
        return (self.year_num + self.year_num // 4) % 7

    @property
    def month_code(self) -> int:
        # Fixed offset per month; accounts for the varying lengths of preceding months.
        return self._MONTH_CODES[self.month - 1]

    @property
    def century_code(self) -> int:
        # Gregorian: cycles through _GREGORIAN_CENTURY_CODES every 400 years.
        # Julian: shifts by 1 each century due to the simpler leap year rule.
        if self.is_gregorian:
            return self._GREGORIAN_CENTURY_CODES[(self.century - 15) % 4]
        return (11 - self.century) % 7

    @property
    def leap_code(self) -> int:
        # Correction for leap years; applies only to January and February (before the leap day).
        if self.is_leap_year and self.month in (1, 2):
            return 1
        return 0

    @property
    def dow_code(self) -> int:
        # Raw result of the DOW formula, mapping to an index in _DAY_NAMES (0=Sunday).
        return (self.year_code + self.month_code + self.century_code + self.day - self.leap_code) % 7

    # ------------------------------------------------------------------
    # Output
    # ------------------------------------------------------------------

    @property
    def month_name(self) -> str:
        # Full English name of the month.
        return self._MONTH_NAMES[self.month - 1]

    @property
    def dow(self) -> str:
        # Full English name of the day of the week.
        return self._DAY_NAMES[self.dow_code]

    @property
    def _verb(self) -> str:
        # All Julian dates predate the Gregorian era and are always in the past.
        if not self.is_gregorian:
            return "was"
        today = _date.today()
        this = (self.year, self.month, self.day)
        now = (today.year, today.month, today.day)
        if this < now:
            return "was"
        if this == now:
            return "is"
        return "will be"

    @property
    def date_long(self) -> str:
        # Human-readable sentence; Julian dates are labelled explicitly.
        suffix = " (Julian)" if not self.is_gregorian else ""
        return f"{self.day} of {self.month_name} {self.year} {self._verb} {self.dow}{suffix}"

    @property
    def info(self) -> str:
        # Intermediate DOW formula codes, useful for debugging or educational purposes.
        return (f"codes: year = {self.year_code}, month = {self.month_code}, "
                f"century = {self.century_code}, leap = {self.leap_code}")

    def __str__(self) -> str:
        return self.date_long

    def __repr__(self) -> str:
        return f"Dow('{self.date}')"


# ----------------------------------------------------------------------
# Usage examples
# ----------------------------------------------------------------------

if __name__ == "__main__":

    today_str = _date.today().strftime("%Y-%m-%d")
    next_jan1  = f"{_date.today().year + 1}-01-01"

    examples = [
        ("0001-01-01", "First supported date"),
        ("1492-10-12", "Columbus lands in the Americas"),
        ("1582-10-04", "Last day of the Julian calendar"),
        ("1582-10-15", "First day of the Gregorian calendar"),
        ("1969-07-20", "Moon landing (Apollo 11)"),
        ("2000-02-29", "Leap day 2000 (Gregorian — divisible by 400)"),
        (today_str,   "Today"),
        (next_jan1,   f"New Year's Day {_date.today().year + 1}"),
        ("9999-12-31", "Last supported date"),
    ]

    for date_str, label in examples:
        d = Dow(date_str)
        print(f"{label}: {d.date_long}")
