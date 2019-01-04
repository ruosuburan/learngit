#!/usr/bin/env python3
# -*- coding: utf-8 -*-
def fact(n):
    '''
    Calculate 1*2*...*n

    >>> fact(1)
    1
    >>> fact(10)
    ?
    >>> fact(-1)
    ?
    '''
    if n < 1:
        raise ValueError()
    if n == 1:
        return 1
    return n * fact(n - 1)
    
print(fact(12))
print(fact(1))
print(fact(-1))
