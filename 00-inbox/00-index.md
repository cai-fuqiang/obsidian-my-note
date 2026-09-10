---
created: 2026-09-04T15:25:01+08:00
modified: 2026-09-10T20:00:51+08:00
share_link: https://share.note.sx/m0ark19j#Un6po3qYF+S7KzSDObLdkg
share_updated: 2026-09-10T15:08:08+08:00
---
# 首页

# 致给自己的座右铭
* <mark style="background:#b1ffff"><font color="#ff0000">写作是唯一重要的事情</font></mark>
## Area
* [[00-kvm-pvm-index|PVM 源码走读 MOC]]
* [[00-kvm-mmu-index|kvm mmu 源码走读]]
## 文献笔记

> [!info] 说明
> 自动汇总 `04-Zettelkasten-Source` 下的全部文献笔记；阅读中的内容优先，其余按最近更新时间排列。

```dataview
TABLE WITHOUT ID
  file.link AS "文献",
  choice(status = "reading", "🟡 阅读中",
    choice(status = "queued", "⚪ 待读",
      choice(status = "processed", "🟢 已整理", "⚠️ 待标记"))) AS "状态",
  default(category, "未分类") AS "分类",
  default(summary, "待补充摘要") AS "摘要",
  dateformat(default(modified, file.mtime), "yyyy-MM-dd") AS "更新"
FROM "04-Zettelkasten-Source"
SORT choice(status = "reading", 1,
  choice(status = "queued", 2,
    choice(status = "processed", 3, 4))) ASC,
  default(modified, file.mtime) DESC
```

## 待补全元数据

```dataview
TABLE WITHOUT ID
  file.link AS "文献",
  default(type, "缺少 type") AS "类型",
  default(status, "缺少 status") AS "状态",
  default(category, "缺少 category") AS "分类",
  default(summary, "缺少 summary") AS "摘要"
FROM "04-Zettelkasten-Source"
WHERE !type OR !status OR !category OR !summary
SORT file.path ASC
```
