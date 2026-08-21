---
type: resource
status: active
created: 2026-08-05
updated: 2026-08-05
summary: 汇总调研PVM-new 中可以继续发展为文章、方案或汇报的主题
projects:
  - "[[01-project/调研PVM-new/调研PVM-new|调研PVM-new]]"
areas: []
mocs: []
sources: []
tags:
  - topic/pvm
  - signal/output
---

# PVM 输出候选

[[01-project/调研PVM-new/调研PVM-new|返回项目主页]]

## MOC 输出方向

```dataview
TABLE WITHOUT ID
  file.link AS "主题",
  output AS "计划产出",
  summary AS "摘要"
FROM "01-project/调研PVM-new"
WHERE type = "moc" AND output
SORT file.mtime DESC
```

## 输出信号

```dataview
TABLE WITHOUT ID
  file.link AS "笔记",
  type AS "类型",
  summary AS "摘要"
FROM "01-project/调研PVM-new"
WHERE contains(file.etags, "#signal/output") AND file.path != this.file.path
SORT file.mtime DESC
```
