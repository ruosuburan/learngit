#!/usr/bin/env python3
# -*- coding: utf-8 -*-
from io import StringIO

# 初始化，说明指针指向0
stringIO = StringIO("abc")
print(stringIO.getvalue())
print(stringIO.tell())

# 写入字符d
stringIO.write("d")
print(stringIO.getvalue())
print(stringIO.tell())

# 移动指针到末尾
stringIO.seek(0, 2)
print(stringIO.getvalue())
print(stringIO.tell())

# 写入字符e
stringIO.write("e")
print(stringIO.getvalue())
print(stringIO.tell()
