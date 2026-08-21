---
type: project
status: active
created: 2026-08-05
updated: 2026-08-05
completed:
due:
priority: 1
summary: 在隔离副本中验证 PARA、文献笔记、永久卡片、MOC 和 Dataview 的完整工作流
projects: []
areas:
  - "[[虚拟化]]"
mocs:
  - "[[01-project/调研PVM-new/MOC/MOC - PVM|MOC - PVM]]"
sources: []
tags:
  - topic/pvm
  - activity/design
---

# 调研PVM-new

> 这是 `调研PVM` 的知识管理实验副本。结构化改造只在本目录进行，原项目不受影响。

## 目标

- 跑通“项目材料 -> 文献笔记 -> 永久卡片 -> MOC -> 输出”的闭环。
- 验证统一字段、受控标签和 Dataview 查询是否好用。
- 形成可复制到其他项目的模板和整理流程。

## 当前结论

- 原目录中大量 `文献笔记` 实际上是 PDF 摘录或单点阅读片段，可以保留为证据层。
- 一篇来源应有一篇主文献笔记，用它串联摘录、个人理解和已提炼卡片。
- 永久卡片必须使用自己的话表达，并通过 `sources` 回到文献笔记。

## 下一步

- [ ] 使用一周，记录字段填写和查询使用中的摩擦。
- [ ] 从 `闪记.md` 再提炼 5 张永久卡片。
- [ ] 将成熟的永久卡片状态从 `seed` 调整为 `linked` 或 `evergreen`。
- [ ] 从 [[01-project/调研PVM-new/MOC/MOC - PVM|MOC - PVM]] 形成一份 PVM 技术介绍。

## 工作入口

- [[01-project/调研PVM-new/00-system/00-home|项目工作台]]
- [[01-project/调研PVM-new/00-system/01-review|每周复盘]]
- [[01-project/调研PVM-new/00-system/02-output|输出候选]]
- [[01-project/调研PVM-new/00-system/标签词表|标签词表]]
- [[01-project/调研PVM-new/MOC/MOC - PVM|MOC - PVM]]
- [[01-project/调研PVM-new/文献笔记/SOSP-2023-PVM|SOSP 2023 PVM 文献笔记]]

## 已结构化笔记

```dataview
TABLE WITHOUT ID
  file.link AS "笔记",
  type AS "类型",
  status AS "状态",
  summary AS "摘要"
FROM "01-project/调研PVM-new"
WHERE contains(projects, this.file.link) AND file.path != this.file.path
SORT type ASC, file.mtime DESC
```

## 尚未迁移的旧材料

```dataview
TABLE WITHOUT ID
  file.link AS "旧材料",
  file.folder AS "目录",
  file.mtime AS "最近修改"
FROM "01-project/调研PVM-new"
WHERE !type
  AND file.ext = "md"
  AND !contains(file.path, "/00-system/templates/")
  AND !contains(file.path, ".excalidraw")
SORT file.mtime DESC
LIMIT 20
```
