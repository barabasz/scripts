class Imagine:
    def __init__(self, real: int, imagine: int) -> None:
        self.r = real
        self.i = imagine

    def __add__(self, second):
        return Imagine(self.r + second.r, self.i + second.i)

    def __sub__(self, second):
        return Imagine(self.r - second.r, self.i - second.i)

    def __str__(self):
        match self.r:
            case 0:
                r = ""
            case _:
                r = self.r
        if self.r == 0 and self.i != 0:
            i = f"{self.i}i"
        else:
            match self.i:
                case 1:
                    i = f" + i"
                case -1:
                    i = f" - i"
                case _ if self.i > 0:
                    i = f" + {self.i}i"
                case _ if self.i < 0:
                    i = f" - {self.i * -1}i"
                case 0:
                    i = ""
        return f"{r}{i}"


z1 = Imagine(0, 2)
print(z1)
z2 = Imagine(2, 0)
print(z2)
z3 = Imagine(1, -1)
print(z3)
z4 = Imagine(-1, 1)
print(z4)
z5 = z1 + z2
print(z5)
z6 = z3 - z4
print(z6)
