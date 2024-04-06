from beautiful_date import *

'''beautiful-date demo'''

print(Apr)

d1 = 15
y1 = 2025

a = d1-Apr-y1
print(type(a), a)

b = (29/Apr/2025)[23:45]
print(type(b), b)

f = BeautifulDate(2018, 3, 25)
print(type(f), f)

c = 5
# print(b - a)
print(a + c*days)
print(b - c*days)

