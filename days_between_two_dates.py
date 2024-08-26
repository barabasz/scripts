from datetime import date

date_1 = date.fromisoformat("2024-01-01")
date_2 = date.fromisoformat("2024-09-03")

if date_2 <= date_1:
    print("The second date must be greater than the first one.")
else:
    days = (date_2 - date_1).days
    verb = "are" if days > 1 else "is"
    noun = "days" if days > 1 else "day"
    print(f"There {verb} {days} {noun} between {date_1} and {date_2}.")
