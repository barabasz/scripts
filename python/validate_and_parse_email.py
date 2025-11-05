#!/usr/bin/env python3

import re
import sys

def validate_and_parse_email(email_string: str) -> tuple | None:
    """
    Validates an email address and returns a tuple (username, domain) or None.
    
    Args:
        email_string: Email address to validate
        
    Returns:
        Tuple (username, domain) if email is valid, None otherwise
    """
    pattern = r'^((?!\.)(?!.*\.\.)[\w!#$%&\'*+\/=?^`{|}~.-]+(?<!\.))@([a-zA-Z0-9](?:[a-zA-Z0-9_-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9_-]{0,61}[a-zA-Z0-9])?)+)$'
    
    match = re.match(pattern, email_string)
    
    if match:
        username = match.group(1)
        domain = match.group(2)
        return username, domain
    
    return None

# Get the first argument from the command line

if len(sys.argv) > 1:
    email = sys.argv[1]
else:
    print("Please provide an email address to validate.")
    sys.exit(1)

result = validate_and_parse_email(email)

if result:
    username, domain = result
    print(f"✅ Email is valid: username: {username}, domain: {domain}")
else:
    print(f"❌ Email is invalid!")