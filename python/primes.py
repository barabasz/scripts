import math


class Primes:
    def __init__(self, start, end):
        self.first = start
        self.last = end
        self.primes = set(range(2, self.last))
        self.sieve()

    def sieve(self):
        for i in range(2, math.isqrt(self.last) + 1):
            if i in self.primes:
                for j in range(i, self.last, i):
                    self.primes.remove(j)

    def print(self):
        print(*self.primes)


p = Primes(5, 25)
p.print()

