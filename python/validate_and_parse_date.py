#!/usr/bin/env python3

import re
import sys

def validate_and_parse_date(date_string: str) -> tuple | None:
    """
    Validates a date and returns a tuple (year, month, day) or None.
    
    Args:
        date_string: Date in YYYY-MM-DD format
        
    Returns:
        Tuple (year, month, day) if date is valid, None otherwise
    """
    pattern = r'^(?:(19[0-9]{2}|[2-9][0-9]{3})-(0[13578]|1[02])-(0[1-9]|[12][0-9]|3[01])|(19[0-9]{2}|[2-9][0-9]{3})-(0[469]|11)-(0[1-9]|[12][0-9]|30)|(19[0-9]{2}|[2-9][0-9]{3})-(02)-(0[1-9]|1[0-9]|2[0-8])|((?:19|[2-9][0-9])(?:0[48]|[2468][048]|[13579][26])|(?:(?:16|[2468][048]|[3579][26])00))-(02)-(29))$'
    
    match = re.match(pattern, date_string)
    
    if match:
        # Filter out None values and take the first 3 values
        values = [g for g in match.groups() if g is not None]
        if len(values) >= 3:
            return values[0], values[1], values[2]
    
    return None

# get the first argument from the command line

if len(sys.argv) > 1:
    date = sys.argv[1]
else:
    print("Please provide a date in YYYY-MM-DD format.")
    sys.exit(1)

result = validate_and_parse_date(date)

if result:
    y, m, d = result
    print(f"✅ Date is valid: year: {y}, month: {m}, day: {d}")
else:
    print(f"❌ Date is invalid!")