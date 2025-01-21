"""
An anagram is a word or phrase formed by rearranging the letters
of a different word or phrase, typically using all the original
letters exactly once.
"""


def is_anagram(str1: str, str2: str) -> bool:
    str1 = "".join(sorted(str1.replace(" ", "").lower()))
    str2 = "".join(sorted(str2.replace(" ", "").lower()))
    return True if str1 == str2 else False


print(is_anagram('listen', 'silent'))
