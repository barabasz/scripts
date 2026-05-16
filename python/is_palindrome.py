def is_palindrome(txt: str | int) -> bool:
    """Return True if txt reads the same forwards and backwards,
    ignoring spaces, punctuation, and case."""
    s = ''.join(c for c in str(txt).lower() if c.isalnum())
    return s == s[::-1]


# True
print(is_palindrome("racecar"))
print(is_palindrome(123454321))
print(is_palindrome("Ave Eva"))
print(is_palindrome("A man, a plan, a canal: Panama"))
print(is_palindrome("Νιψον Ανομeματα Μe Μοναν Οψιν"))

# False
print(is_palindrome("racecart"))
print(is_palindrome(23454321))
print(is_palindrome("Ave Ewa"))
