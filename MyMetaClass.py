#!/usr/bin/env python3
# -*- coding: utf-8 -*-

# metaclass是创建类，所以必须从`type`类型派生：
class ListMetaclass(type):
    def new(cls, name, bases, attrs):
        print('new===> ',cls, name, bases, attrs)
        aaa = lambda self, value: print('self:',self,',value:',value,'self添加value前:',self.append(value),',self添加value后:',self)
        attrs['add'] = aaa
        print('===> ', cls, name, bases, attrs)
        return type.new(cls, name, bases, attrs)

class MyList(list, metaclass=ListMetaclass):
    pass

L = MyList()
print("------定义完成---------")
L.add(1)
L.add(2)
print(L)
