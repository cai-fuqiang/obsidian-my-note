---
type: resource
status: active
created: 2026-08-05
updated: 2026-08-05
summary: 调研PVM-new 的局部工作台，集中展示阅读、提炼和近期进展
projects:
  - "[[01-project/调研PVM-new/调研PVM-new|调研PVM-new]]"
areas: []
mocs: []
sources: []
tags:
  - topic/pvm
---

# PVM 项目工作台

[[01-project/调研PVM-new/调研PVM-new|返回项目主页]]

## 正在阅读

```dataview
TABLE WITHOUT ID
  file.link AS "文献",
  status AS "状态",
  summary AS "摘要"
FROM "01-project/调研PVM-new"
WHERE type = "literature" AND (status = "queued" OR status = "reading")
SORT file.mtime ASC
```

## 待处理记录

```dataview
TABLE WITHOUT ID
  file.link AS "记录",
  type AS "类型",
  summary AS "摘要"
FROM "01-project/调研PVM-new"
WHERE status = "captured"
SORT file.ctime ASC
```

## 最近更新

```dataview
TABLE WITHOUT ID
  file.link AS "笔记",
  type AS "类型",
  status AS "状态",
  summary AS "摘要"
FROM "01-project/调研PVM-new"
WHERE type AND file.path != this.file.path
SORT file.mtime DESC
LIMIT 12
```
