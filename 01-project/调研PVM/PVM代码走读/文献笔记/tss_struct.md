# 数据结构
**内核中使用`tss_struct`** 数据结构来描述TSS:

```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/linux/v7.1-rc3/arch/x86/include/asm/processor.h"
LINES: "405-414"
TITLE: "tss_struct"
FONT_SIZE: 12
COMMENTS:
```

其中
* x86_tss: 硬件需要的tss结构
* io_bitmap: `x86_tss->io_bitmap_base` 指向的数据结构

而`struct x86_hw_tss` 根据32-bit 还是64-bit 分为两种定义，这里我们只关注64-bit


```ad-note
title: x86_hw_tss
collapse: true
````embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/linux/v7.1-rc3/arch/x86/include/asm/processor.h"
LINES: "313-333"
TITLE: "x86_hw_tss"
FONT_SIZE: 10
COMMENTS:
````

和硬件定义一致
