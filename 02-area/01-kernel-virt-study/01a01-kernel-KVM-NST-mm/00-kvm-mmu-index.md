---
created: 2026-09-10T18:01:59+08:00
modified: 2026-09-11T15:33:54+08:00
share_link: https://share.note.sx/8lg8yt9c#lh4b7UE6tGVkK/Mb4U/Tig
share_updated: 2026-09-11T11:38:21+08:00
---
# KVM-mmu

## 源码笔记

```dataview
TABLE WITHOUT ID
  category AS "分类",
  file.link AS "笔记",
  summary AS "当前结论",
  choice(status = "processed", "已整理",
    choice(status = "reading", "阅读中", status)) AS "状态"
FROM "04-Zettelkasten-Source/01a-kvm-mmu"
SORT category ASC
```

# Q&A

```dataview
TABLE WITHOUT ID
  QA AS "问题",
  rows.file.link AS "笔记"
FROM "04-Zettelkasten-Source/01a-kvm-mmu"
FLATTEN QA AS 问题
GROUP BY QA
SORT QA ASC
```
