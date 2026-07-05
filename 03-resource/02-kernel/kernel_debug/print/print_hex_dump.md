
# print_hex_dump

```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/linux/v7.1-rc3/include/linux/printk.h"
LINES: "773-776"
TITLE: "print_hex_dump"
FONT_SIZE: 13px
```

参数解释
* level: printk level 参考  ![[printk level]]
* prefix_str: 前缀, 在打印raw buffer data 之前打印
* prefix_type: 

```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/linux/v7.1-rc3/include/linux/printk.h"
LINES: "760-764"
TITLE: "prefix_type"
FONT_SIZE: "14px"
```
* rowsize: row 中文是行，该变量表示行的长度
* groupsize: 一行打印中保唅多组数据，每组数据用 `' '`(空格字符)隔开，该变量表示每组数据的长度
* buf:
* len: buflen
* ascii : 转换为ascii 字符，适合打印字符串