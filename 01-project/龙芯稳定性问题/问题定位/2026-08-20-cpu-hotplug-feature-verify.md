---
data: 2026-08-20
问题分类: cpu hotplug
是否定位成功: true
目前结论: 使用当前qemu以及openeuler upstream qemu未复现问题
is_issue: true
instance: --
share_link: https://share.note.sx/pnhm0gz2#R650mNafiAG3B6T9uSWOVg
share_updated: 2026-08-20T16:29:11+08:00
---

# 问题现象

香来在执行热插，热拔再热插后，会遇到下面问题:
```
[647.449576][ T1010] CPU1: failed to start
```

# 自测

> [!summary]
> 经本地测试:
> * 公司使用的内核+ 公司使用的qemu
> * 公司使用的内核+ qemu-upstream(base commit e39c2a9009) 
> 均无法复现
