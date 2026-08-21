---
type: resource
status: active
created: 2026-08-05
updated: 2026-08-05
summary: 调研PVM-new 的每周复盘页，检查未提炼文献、种子卡片和旧材料迁移候选
projects:
  - "[[01-project/调研PVM-new/调研PVM-new|调研PVM-new]]"
areas: []
mocs: []
sources: []
tags:
  - topic/pvm
  - signal/review
---

# PVM 每周复盘

[[01-project/调研PVM-new/调研PVM-new|返回项目主页]]

## 未完成的文献加工

```dataview
TABLE WITHOUT ID
  file.link AS "文献",
  status AS "状态",
  summary AS "摘要"
FROM "01-project/调研PVM-new"
WHERE type = "literature" AND status != "processed" AND status != "abandoned"
SORT file.mtime ASC
```

## 种子和弱连接卡片

```dataview
TABLE WITHOUT ID
  file.link AS "卡片",
  status AS "状态",
  sources AS "来源",
  mocs AS "MOC",
  summary AS "摘要"
FROM "01-project/调研PVM-new/永久卡片"
WHERE type = "permanent" AND (status = "seed" OR length(file.outlinks) < 2)
SORT file.mtime ASC
```

## 缺少核心字段

```dataview
TABLE WITHOUT ID
  file.link AS "文件",
  type AS "类型",
  status AS "状态",
  summary AS "摘要"
FROM "01-project/调研PVM-new/00-system" OR "01-project/调研PVM-new/MOC" OR "01-project/调研PVM-new/永久卡片"
WHERE !contains(file.path, "/templates/") AND (!type OR !status OR !summary)
SORT file.mtime DESC
```

## 下一批旧材料候选

```dataview
TABLE WITHOUT ID
  file.link AS "候选材料",
  file.mtime AS "最近修改"
FROM "01-project/调研PVM-new/文献笔记"
WHERE !type
SORT file.mtime DESC
LIMIT 10
```
