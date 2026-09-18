---
type: moc
status: active
created: 2026-09-04
updated: 2026-09-04
summary: 从运行模式、syscall、事件、地址空间和上下文保存五条路径组织 PVM/KVM 源码阅读
modified: 2026-09-17T18:13:03+08:00
---
# PVM/KVM 源码阅读

## 永久笔记

```dataview
TABLE WITHOUT ID
  category AS "分类",
  file.link AS "笔记",
  summary AS "核心观点",
  choice(status = "linked", "已连接",
    choice(status = "evergreen", "常青", "种子")) AS "状态"
FROM "03-Zettelkasten/01u-kvm-pvm"
WHERE type = "permanent"
SORT choice(category = "运行模式", 10,
  choice(category = "syscall", 20,
    choice(category = "事件与返回", 30,
      choice(category = "MMU与地址空间", 40, 50)))) ASC,
  file.name ASC
```


## 源码笔记

```dataview
TABLE WITHOUT ID
  category AS "分类",
  file.link AS "笔记",
  summary AS "当前结论",
  choice(status = "processed", "已整理",
    choice(status = "reading", "阅读中", status)) AS "状态"
FROM "04-Zettelkasten-Source/01u-kvm-pvm"
SORT category ASC
```


# Q&A

```dataview
TABLE WITHOUT ID
  QA AS "问题",
  rows.file.link AS "笔记"
FROM "04-Zettelkasten-Source/01u-kvm-pvm"
FLATTEN QA AS 问题
GROUP BY QA
SORT QA ASC
```
