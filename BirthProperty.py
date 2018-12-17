#!/usr/bin/env python3
# -*- coding: utf-8 -*-

class Student(object):

    @property
    def birth(self):
        return self._birth

    @birth.setter
    def birth(self, value):
        if not isinstance(value, int):
            raise ValueError('birth must be an integer!')
        if value < 0 or value > 100:
            raise ValueError('birth must between 0 ~ 100!')
        self._birth = value
    @property
    def age(self):
        return 2015 - self._birth
s = Student()
s.birth = 45
print('s.birth =', s.birth)
print('s.age=',s.age)
# ValueError: birth must between 0 ~ 100!
s.birth=120
print('s.birth =', s.birth)
