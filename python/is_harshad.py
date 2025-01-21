"""
harshad number (or Niven number) in a given number base is an integer
that is divisible by the sum of its digits when written in that base
"""


def sum_digits(number: int) -> int:
    total = 0
    while number > 0:
        total += number % 10
        number //= 10
    return total


def is_harshad(number: int) -> bool:
    if number % sum_digits(number) == 0:
        return True
    else:
        return False


x = 12345
print(is_harshad(x))
