"""
A palindrome is a word, number, phrase, or other sequence
of symbols that reads the same backwards as forwards
"""


def is_palindrome(txt: str or int) -> bool:
    s = str(txt).replace(" ", "").lower()
    return True if s == s[::-1] else False


# True
print(is_palindrome("racecar"))
print(is_palindrome(123454321))
print(is_palindrome("Ave Eva"))
print(is_palindrome("Νιψον Ανομeματα Μe Μοναν Οψιν"))

# False
print(is_palindrome("racecart"))
print(is_palindrome(23454321))
print(is_palindrome("Ave Ewa"))
print(is_palindrome("Νιψο Ανομeματα Μe Μοναν Οψιν"))