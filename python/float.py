# float problem

a = 0.1 + 0.1 + 0.1 + 0.1 + 0.1 + 0.1 + 0.1 + 0.1 + 0.1 + 0.1
print(a, type(a)) # 0.9999999999999999 float

b = 0.1 * 10
print(b, type(b)) # 1.0 float

from decimal import Decimal
c = sum(Decimal(0.1) for _ in range(10))
print(c, type(c)) # 1.000000000000000055511151231 Decimal

d = sum(Decimal(str(0.1)) for _ in range(10))
print(d, type(d)) # 1.0 Decimal
