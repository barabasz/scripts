def sum_digits(number: int) -> int:
    total = 0
    while number > 0:
        total += number % 10
        number //= 10
    return total


def sum_digits2(number: int) -> int:
    total = 0
    for i in str(number):
        total += int(i)
    return total


n = 123456
print(sum_digits(n))
print(sum_digits2(n))