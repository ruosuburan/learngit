
reduce(f,[x1,x2,x3,x4])=f(f(f(x1,x2),x3),x4)
from functools import reduce
def add(x,y):
     return 10*x-y
print(reduce(add,[4,2,5,1,6]))