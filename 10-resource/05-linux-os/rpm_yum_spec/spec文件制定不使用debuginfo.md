---
status: done
show in nav: true
create date: 2026-07-01 10:46:35
complete date: 2026-07-01 10:46:50
tags:
priority: 99
summary:
---

# 方法一: 修改spec文件
在spec开头添加
```
*%global debug_package %{nil}*
```


# 方法二: 命令行参数禁用
```
rpmbuild -ba --without debuginfo xxx.spec
```