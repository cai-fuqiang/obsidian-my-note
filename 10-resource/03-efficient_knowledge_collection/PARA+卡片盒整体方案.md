---
type: resource
status: draft
created: 2026-08-05
updated: 2026-08-05
completed:
aliases:
  - PARA+卡片盒整体方案
  - Obsidian 知识管理整体方案
summary: 面向当前 vault 的 PARA+卡片盒整理方案，目标是把项目推进、领域积累、资料保存和永久卡片沉淀分开，并用索引与复盘流程让笔记产生复用价值。
projects: []
areas: []
mocs: []
sources: []
tags:
  - topic/obsidian
  - topic/knowledge-management
  - activity/design
---

# PARA+卡片盒整体方案

## 1. 当前诊断

当前 vault 已经有 PARA 的外壳：

- `01-project`: PVM 调研、CVE、龙芯稳定性、kprobe 等正在推进的工作。
- `02-area`: kernel、datasheet、客户问题、daily、脚本等长期责任区。
- `03-resource`: QEMU/KVM、kernel、Obsidian、PDF、模板等主题资料。
- `04-archive`: 旧资料、剪藏、旧模板、历史问题。

但还没有形成稳定的知识生产闭环。主要问题是：

- `项目笔记`、`文献摘录`、`永久卡片` 和 `资料存档` 混在同一项目目录里，例如 `01-project/调研PVM/闪记.md` 同时承担 PDF 摘录、翻译、评论、问题列表、半成品卡片等职责。
- `03-resource` 中有高质量长文，但它们更像主题文章或资料页，不完全等同于卡片盒中的永久卡片。
- 元数据字段不统一，现有 `status`、`summary`、`show in nav`、`is_issue` 已经有价值，但关系字段仍缺少统一的命名、类型和允许值，跨目录查询容易不断增加兼容分支。
- 当前导航主要集中在 `03-resource/00-NAV.md`，还缺少 `项目驾驶舱`、`领域驾驶舱`、`卡片收件箱`、`待连接卡片`、`可输出主题` 这些真正驱动复用的视图。

结论：不要先大规模搬文件。先补上“笔记类型”和“流转规则”，让旧笔记逐步被索引和转化。

## 2. 核心设计原则

### PARA 负责行动

PARA 只回答一个问题：这条信息现在服务什么行动？

- `Project`: 有明确完成标准和截止/阶段目标的事情。
- `Area`: 需要长期维护的责任领域。
- `Resource`: 暂时没有行动压力，但未来可能复用的主题资料。
- `Archive`: 已完成、暂停、过期、只保留备查的内容。

### 卡片盒负责思想

卡片盒只回答一个问题：这条想法能否脱离当前项目，在未来被重新组合？

永久卡片不按项目存放，也不按文件夹层级表达意义。它依靠：

- 原子化观点。
- 明确上下文。
- 至少一个入链或出链。
- 来源可追溯。
- 自己的话重写。

### 两套系统的关系

PARA 是工作台，卡片盒是知识库。

- 项目中产生问题、证据、调试记录、阅读摘录。
- 每日或每周从项目材料中提炼永久卡片。
- 永久卡片反过来支撑项目总结、技术方案、文章、排障手册。

## 3. 推荐目录结构

保留现有 PARA 顶层目录，新增少量系统目录：

```text
00-system/
  00-home.md
  01-inbox.md
  02-review.md
  03-output.md
  04-dashboard-projects.md
  05-dashboard-cards.md

01-project/
  <项目名>/
    <项目名>.md
    logs/
    sources/
    outputs/
    archive/

02-area/
  <领域名>/
    <领域名>.md
    standards/
    checklists/
    playbooks/

03-resource/
  <主题>/
    <主题 MOC>.md
    references/
    notes/

04-archive/

05-cards/
  permanent/
  literature/
  concept/
  index/

06-attachments/
  pdf/
  images/
  excalidraw/
```

说明：

- `00-system` 是操作入口，不放知识内容，只放仪表盘、收件箱、复盘页。
- `05-cards/permanent` 是真正的卡片盒。永久卡片从项目、阅读、调试中提炼出来，不跟着项目归档。
- `05-cards/literature` 放文献笔记。它可以保留 PDF 链接、引用、页码、摘录，但每篇文献应该有独立笔记，不建议所有摘录堆到一个 `闪记.md`。
- `05-cards/concept` 放概念解释类笔记，例如 `shadow VMCS`、`SPT-on-EPT`、`QOM TypeInfo`。
- `05-cards/index` 放 MOC 或关键词索引，例如 `MOC - 嵌套虚拟化.md`、`MOC - QEMU 设备热插拔.md`。
- `03-resource` 仍然保留主题资料和长文，但高复用观点要提炼到 `05-cards`。

## 4. 笔记类型定义

### 4.1 项目笔记

放在 `01-project/<项目名>/`。

用途：推进一个具体目标。

必须回答：

- 目标是什么？
- 现在卡在哪里？
- 下一步是什么？
- 最终产出放在哪里？

推荐 frontmatter：

```yaml
---
type: project
status: active
created: 2026-08-05
updated: 2026-08-05
completed:
due:
priority: 1
summary: 验证 PVM 的关键机制、性能收益和适用边界
projects: []
areas:
  - "[[虚拟化]]"
mocs:
  - "[[MOC - PVM]]"
sources: []
tags:
  - topic/pvm
---
```

项目主页推荐结构：

```markdown
# 项目名

## 目标

## 当前结论

## 下一步

## 关键问题

## 资料入口

## 已产出

## 待提炼卡片
```

### 4.2 日志/调试笔记

放在项目下的 `logs/`，也可以暂时保留在项目根目录。

用途：保留时间线、现象、命令、堆栈、实验记录。

要求：

- 可以很长。
- 可以粗糙。
- 必须有结论区。
- 必须标出哪些段落值得提炼成卡片。

推荐字段：

```yaml
---
type: log
status: captured
created: 2026-08-05
updated: 2026-08-05
summary: 复现并定位 PVM 启动阶段的 world switch 异常
projects:
  - "[[调研PVM]]"
areas:
  - "[[虚拟化]]"
mocs: []
sources: []
tags:
  - topic/pvm
  - activity/debugging
---
```

### 4.3 文献笔记

放在 `05-cards/literature/`。

用途：记录一篇论文、文档、博客、spec 的阅读过程。

它可以包含摘录，但不应止步于摘录。每篇文献笔记最终至少产出若干永久卡片。

推荐字段：

```yaml
---
type: literature
status: reading
created: 2026-08-05
updated: 2026-08-05
summary: 阅读 PVM 的 world switch 实现及其设计动机
source_url:
citekey:
authors: []
published:
projects:
  - "[[调研PVM]]"
areas:
  - "[[虚拟化]]"
mocs:
  - "[[MOC - PVM]]"
sources: []
tags:
  - topic/pvm
  - activity/code-reading
---
```

推荐结构：

```markdown
# 文献标题

## 一句话

## 为什么读

## 关键摘录

## 我的理解

## 可转化卡片

## 相关卡片
```

### 4.4 永久卡片

放在 `05-cards/permanent/`。

用途：保存一个可以长期复用的独立想法。

永久卡片标准：

- 一张卡只表达一个观点。
- 标题是判断句或问题句，不是大类名。
- 正文用自己的话写。
- 至少链接 2 个对象：一个来源或证据，一个相关卡片/MOC/项目。
- 能被未来的你读懂，不依赖当天上下文。

推荐字段：

```yaml
---
type: permanent
status: seed
created: 2026-08-05
updated: 2026-08-05
summary: 嵌套虚拟化通过增加多级状态切换放大一次 VM-exit 的成本
projects:
  - "[[调研PVM]]"
areas:
  - "[[虚拟化]]"
mocs:
  - "[[MOC - 嵌套虚拟化]]"
sources:
  - "[[Intel-SDM-VMCS]]"
tags:
  - topic/kvm
  - topic/nested-virtualization
---
```

推荐结构：

```markdown
# 标题

## 观点

## 依据

## 适用边界

## 相关
```

标题示例：

- `嵌套虚拟化的主要成本不是单次 VM-exit，而是多级转发导致的 world switch 放大`
- `GPT2 只读是 SPT 同步的触发机制`
- `QEMU 热插拔路径需要同时看 QMP、设备模型和 ACPI 通知`

### 4.5 MOC/索引笔记

放在 `05-cards/index/` 或主题目录根部。

用途：不是收集所有资料，而是组织一条思考路径。

推荐字段：

```yaml
---
type: moc
status: active
created: 2026-08-05
updated: 2026-08-05
summary: 组织 PVM 的设计动机、切换机制、实现路径和性能证据
projects:
  - "[[调研PVM]]"
areas:
  - "[[虚拟化]]"
mocs: []
sources: []
output:
tags:
  - topic/pvm
---
```

推荐结构：

```markdown
# MOC - 主题名

## 我现在如何理解这个主题

## 核心问题

## 概念地图

## 关键卡片

## 可输出题目

## 空白区
```

MOC 的职责是“带路”，不是“存东西”。

## 5. 信息流转

### 5.1 捕获

入口统一进入：

- 每日笔记：临时想法、任务、碎片。
- 项目 `logs/`：调试过程、实验记录、问题现场。
- 文献笔记：PDF、spec、博客、论文摘录。
- `00-system/01-inbox.md`：无法判断归属的材料。

捕获阶段允许粗糙，只要求能回到现场。

### 5.2 加工

每天或每周做一次短加工：

1. 从 daily 和项目日志中找出“可复用想法”。
2. 从文献摘录中找出“我自己的判断”。
3. 新建永久卡片。
4. 给卡片补来源、项目、领域、MOC。
5. 至少建立 2 个链接。

### 5.3 连接

每张永久卡片写完后必须问三个问题：

- 它支持哪个项目？
- 它属于哪个长期领域？
- 它能和哪张旧卡片产生关系？

如果暂时找不到旧卡片，链接到一个 MOC，并标记 `type: permanent`、`status: seed`。

### 5.4 输出

输出不是从空白页开始，而是从 MOC 或项目主页开始：

- 技术方案：从项目主页收敛。
- 排障手册：从多个 issue/log 卡片抽象。
- 文章：从 MOC 的概念路径展开。
- 汇报材料：从项目输出目录生成。

## 6. 当前笔记迁移策略

### 第一阶段：只加索引，不搬家

目标：一周内让当前 vault 可控。

动作：

- 新建 `00-system/00-home.md`，作为唯一入口。
- 新建项目 Dashboard，列出 `01-project` 下所有 active 项目。
- 新建卡片 Dashboard，列出 `type: permanent`、`type: literature` 和 `status: seed`。
- 给现有项目主页补 `type: project`、`status`、`summary`。
- 给高价值长文补 `type: resource` 或 `type: literature`。

不要做：

- 不要一次性移动 200 多个文件。
- 不要强行给所有旧笔记补完整元数据。

### 第二阶段：围绕 PVM 做样板

目标：用一个真实项目打通闭环。

建议先选 `01-project/调研PVM`，因为它已经有大量 PDF 摘录和文献卡片雏形。

动作：

- 把 `01-project/调研PVM/闪记.md` 拆成一篇或多篇文献笔记。
- 将已经独立成型的 `文献笔记/*.md` 中的观点迁移或复制为 `05-cards/permanent/` 卡片。
- 建立 `05-cards/index/MOC - PVM.md`。
- 项目主页只保留目标、路线、问题、结论、输出链接。

样板完成标准：

- 至少 1 个项目主页。
- 至少 1 个 MOC。
- 至少 1 篇文献笔记。
- 至少 20 张永久卡片。
- 每张永久卡片至少 2 个链接。

### 第三阶段：整理领域和资源

目标：让长期积累可复用。

动作：

- `02-area/01-kernel` 作为长期领域，建立 `02-area/01-kernel/kernel.md`。
- `03-resource/01-QEMU_KVM` 中的长文保留，但抽出核心概念卡片。
- `02-area/05-datasheet` 更适合移动到 `03-resource` 或 `06-attachments/pdf` 附近，除非它代表长期维护责任。
- `Clippings` 统一进入 `03-resource` 或 `05-cards/literature`，剪藏不直接进入永久卡片盒。

### 第四阶段：归档

目标：降低噪声。

归档规则：

- 项目完成或暂停超过 30 天，移入项目内 `archive/` 或顶层 `04-archive`。
- 已转化为永久卡片的原始摘录可以保留，但不再作为主要入口。
- 临时文件如 `tmp.md`、`草稿.md` 每周处理一次：删除、归档、提炼三选一。

## 7. Dataview 与标签顶层设计

### 7.1 四层职责

不要让目录、字段、链接和标签表达同一件事。它们各自只承担一种职责：

| 层 | 负责回答 | 示例 |
|---|---|---|
| 目录 | 这份材料当前处于哪个行动环境 | `01-project`、`02-area`、`03-resource`、`04-archive` |
| YAML 字段 | 这是什么、处于什么状态、与谁有明确关系 | `type`、`status`、`projects`、`areas` |
| 双链和 MOC | 这条知识在语义上与什么相连 | `[[MOC - KVM MMU]]`、`[[EPT 违例并不等于缺页]]` |
| 标签 | 它还具有哪些可多选、跨目录的横向特征 | `#topic/kvm`、`#activity/code-reading` |

Dataview 只是上述元数据的“视图层”，不作为知识来源。查询坏了，笔记和链接仍然应当可以独立阅读。

### 7.2 统一字段协议

新笔记统一使用下面这组字段。关系字段全部使用复数，并始终写成列表；即使当前只有一个值，也不要改成单值。这样 Dataview 查询不需要兼容多种数据类型。

```yaml
---
type: literature
status: reading
created: 2026-08-05
updated: 2026-08-05
completed:
summary: 阅读 PVM 的 world switch 实现及其设计动机
projects:
  - "[[调研PVM]]"
areas:
  - "[[虚拟化]]"
mocs:
  - "[[MOC - PVM]]"
sources: []
tags:
  - topic/pvm
  - activity/code-reading
---
```

核心字段：

- `type`：笔记是什么。允许值为 `project`、`area`、`resource`、`literature`、`permanent`、`moc`、`log`、`daily`、`issue`。
- `status`：该类型笔记当前处于什么阶段。状态值必须与 `type` 配套使用。
- `created`、`updated`、`completed`：统一使用 `YYYY-MM-DD`，不再新增 `create date`、`complete date` 等变体。
- `summary`：用自己的话写一句话摘要，供列表扫描；不是复制标题。
- `projects`：当前服务或产生它的项目，值为项目主页的双链。
- `areas`：所属长期责任领域，值为领域主页的双链。
- `mocs`：进入哪些主题地图，值为 MOC 双链。
- `sources`：它依据的库内文献笔记或其他原始笔记，永久卡片尤其需要。

按类型增加的可选字段：

| 类型 | 可选字段 | 用途 |
|---|---|---|
| `project` | `priority`、`due` | 项目排序和截止日期 |
| `literature` | `source_url`、`citekey`、`authors`、`published` | 记录外部来源；不要把 URL 混入 `sources` |
| `permanent` | `review_after` | 需要定期复核的时效性结论 |
| `moc` | `output` | 计划形成的文章、汇报或方案 |
| `issue` | `severity`、`category`、`instance` | 问题分级和统计；生命周期由 `status` 表示 |

状态词表：

| `type` | 允许的 `status` |
|---|---|
| `project` | `active`、`paused`、`done`、`archived` |
| `literature` | `queued`、`reading`、`processed`、`abandoned` |
| `permanent` | `seed`、`linked`、`evergreen`、`deprecated` |
| `log`、`daily` | `captured`、`processed` |
| `issue` | `open`、`investigating`、`resolved`、`wontfix` |
| `area` | `active`、`stable`、`deprecated` |
| `resource`、`moc` | `draft`、`active`、`stable`、`deprecated` |

不要再增加 `card_status`。永久卡片的成熟度直接使用 `status`，所有查询都先限定 `type`，因此不会与项目状态混淆。

### 7.3 标签协议

标签只保留三个命名空间：

- `topic/*`：跨目录、会重复出现的技术主题，如 `topic/kvm`、`topic/qemu`、`topic/mmu`、`topic/scheduler`、`topic/arm64`。
- `activity/*`：产生这份笔记的工作方式，如 `activity/code-reading`、`activity/debugging`、`activity/experiment`、`activity/design`、`activity/howto`。
- `signal/*`：需要特别关注的临时信号，如 `signal/question`、`signal/review`、`signal/output`。

明确禁止用标签表示以下信息：

- 不用 `#project/PVM`：使用 `projects: ["[[调研PVM]]"]`。
- 不用 `#status/done`：使用 `status: done`。
- 不用 `#type/permanent`：使用 `type: permanent`。
- 不用 `#area/kernel`：使用 `areas: ["[[Kernel]]"]`。
- 不把每个函数名、文件名、错误码都做成标签；它们更适合正文、链接或搜索。

标签维护规则：

- 每篇笔记通常使用 0 到 5 个标签。
- 新标签只有在预计至少会用于 3 篇笔记时才创建。
- 全部使用小写 ASCII 和短横线，避免 `KVM`、`kvm`、`虚拟化/kvm` 并存。
- 在 `00-system/标签词表.md` 维护允许使用的标签及含义；未进入词表的标签视为待整理标签。

初始词表先保持小而稳定：

```text
topic/virtualization  topic/kvm       topic/qemu
topic/pvm             topic/kernel    topic/mmu
topic/scheduler       topic/arm64     topic/x86
topic/loongarch       topic/storage   topic/obsidian
topic/knowledge-management

activity/code-reading activity/debugging activity/experiment
activity/design       activity/howto

signal/question       signal/review      signal/output
```

`#excalidraw` 等由插件维护的标签列入词表中的“系统例外”，不参与业务标签命名规则。

### 7.4 Dataview 三层架构

Dataview 看板分为三层，不为每个目录重复制造一套查询。

第一层是全局行动看板，放在 `00-system`：

- `00-home.md`：活跃项目、正在阅读、待处理记录、近期更新。
- `01-review.md`：未提炼文献、种子卡片、孤立卡片、缺少元数据的文件。
- `02-output.md`：带有 `signal/output` 或 MOC `output` 字段的候选输出。

第二层是上下文看板：

- 每个项目主页只查询 `projects` 包含当前项目的笔记。
- 每个领域主页只查询 `areas` 包含当前领域的笔记。
- 每个 MOC 只查询 `mocs` 包含当前 MOC 的文献笔记和永久卡片，再由人工编排核心链接。

第三层是系统健康检查：

- 是否缺少 `type`、`status`、`summary`。
- 是否仍有 `captured`、`queued`、`seed` 长期未处理。
- 永久卡片是否缺少来源或链接。
- 是否出现未按命名空间管理的标签。

### 7.5 全局看板查询

活跃项目：

```dataview
TABLE WITHOUT ID
  file.link AS "项目",
  default(priority, 99) AS "优先级",
  due AS "截止",
  summary AS "当前目标"
FROM "01-project"
WHERE type = "project" AND status = "active"
SORT default(priority, 99) ASC, due ASC
```

阅读与提炼队列：

```dataview
TABLE WITHOUT ID
  file.link AS "文献",
  status AS "状态",
  projects AS "项目",
  summary AS "摘要"
FROM ""
WHERE type = "literature" AND (status = "queued" OR status = "reading")
SORT file.mtime ASC
```

待处理捕获：

```dataview
TABLE WITHOUT ID
  file.link AS "记录",
  type AS "类型",
  projects AS "项目",
  summary AS "摘要"
FROM ""
WHERE status = "captured"
SORT file.ctime ASC
```

种子和弱连接卡片：

```dataview
TABLE WITHOUT ID
  file.link AS "卡片",
  status AS "状态",
  sources AS "来源",
  mocs AS "MOC",
  summary AS "摘要"
FROM ""
WHERE type = "permanent" AND (status = "seed" OR length(file.outlinks) < 2)
SORT file.mtime ASC
```

元数据缺失检查：

```dataview
TABLE WITHOUT ID
  file.link AS "文件",
  type AS "类型",
  status AS "状态",
  summary AS "摘要"
FROM ""
WHERE !contains(file.path, "1000-Templates")
  AND !contains(file.path, ".excalidraw")
  AND (!type OR !status OR !summary)
SORT file.mtime DESC
```

这个查询在迁移早期会列出很多旧笔记，属于正常现象。先只修复近期仍在使用的文件，不要为了清空列表一次性修改全部历史笔记。

非规范标签检查：

```dataview
TABLE WITHOUT ID
  file.link AS "文件",
  tag AS "待整理标签"
FROM ""
FLATTEN file.etags AS tag
WHERE tag != "#excalidraw"
  AND !startswith(tag, "#topic/")
  AND !startswith(tag, "#activity/")
  AND !startswith(tag, "#signal/")
SORT tag ASC, file.name ASC
```

输出候选：

```dataview
TABLE WITHOUT ID
  file.link AS "主题",
  type AS "类型",
  output AS "计划产出",
  summary AS "摘要"
FROM ""
WHERE (type = "moc" AND output) OR contains(file.etags, "#signal/output")
SORT file.mtime DESC
```

### 7.6 项目与 MOC 查询

项目主页中的相关材料：

```dataview
TABLE WITHOUT ID
  file.link AS "笔记",
  type AS "类型",
  status AS "状态",
  summary AS "摘要"
FROM ""
WHERE contains(projects, this.file.link) AND file.path != this.file.path
SORT type ASC, file.mtime DESC
```

MOC 中的关联知识：

```dataview
TABLE WITHOUT ID
  file.link AS "笔记",
  type AS "类型",
  status AS "状态",
  summary AS "摘要"
FROM ""
WHERE contains(mocs, this.file.link) AND file.path != this.file.path
SORT choice(type = "permanent", 1, 2) ASC, file.name ASC
```

Dataview 生成的是“候选集合”，MOC 正文中的概念顺序、因果关系和核心路径仍然要人工书写。自动列表不能替代思考。

### 7.7 旧字段迁移

现有库不需要一次性重写，按“新笔记用新协议，旧笔记被再次使用时再迁移”的方式执行：

| 旧字段 | 新字段或处理方式 |
|---|---|
| `create date`、`create-date` | `created` |
| `complete date`、`complete-date` | `completed` |
| `project` | `projects`，改为双链列表 |
| `area` | `areas`，改为双链列表 |
| `moc` | `mocs`，改为双链列表 |
| `source` | 库内来源改为 `sources`；外部链接改为 `source_url` |
| `card_status` | 合并到永久卡片的 `status` |
| `show in nav` | 逐步废弃，由 `type`、`status` 和上下文字段自动决定是否显示 |
| `is_issue` | 新问题改用 `type: issue`；旧问题看板暂时兼容 |

`03-resource/00-NAV.md` 在迁移期可以继续工作。等常用资源补齐新字段后，再将它替换为按 `type: resource` 和 `status` 查询的资源主页。

## 9. 命名规则

### 项目

```text
01-project/调研PVM/调研PVM.md
01-project/CVE-2026-53359/CVE-2026-53359.md
```

### 日志

```text
YYYY-MM-DD-问题或实验名.md
```

示例：

```text
2026-07-30-i-23m7r699sd-softlockup.md
```

### 文献笔记

```text
作者或组织-年份-短标题.md
```

示例：

```text
Alibaba-2023-PVM.md
Intel-SDM-VMCS.md
```

### 永久卡片

标题直接写观点，不需要编号前缀。

示例：

```text
嵌套虚拟化会放大 world switch 成本.md
GPT2 只读用于捕获客户机页表更新.md
```

## 10. 每日和每周流程

### 每日 10 分钟

- 清理当天 daily 的 `flash of thought`。
- 把任务移动到项目主页或 Tasks。
- 把有价值的想法转成 1 到 3 张永久卡片。
- 对新卡片至少补 2 个链接。

### 每周 30 分钟

- 打开 `待提炼材料` 面板。
- 每个 active 项目写一句当前结论。
- 每个 active 项目写一个下一步。
- 检查孤立卡片。
- 更新 1 到 2 个 MOC。
- 把完成/暂停项目归档。

## 11. 迁移优先级

建议顺序：

1. 建 `00-system` 与 Dashboard。
2. 给项目主页补 `type: project`。
3. 用 `调研PVM` 做完整样板。
4. 从 `闪记.md` 提炼 PVM 永久卡片。
5. 给 `龙芯稳定性问题` 建项目主页和 issue 模板。
6. 给 `03-resource/01-QEMU_KVM` 建 MOC，并从长文中抽卡。
7. 整理 `Clippings` 和 `04-archive/Clippings`，只把有价值内容转文献笔记。
8. 最后再考虑移动附件和历史资料。

## 12. 判断系统是否有效

一套 PARA+卡片盒系统有效，不是因为目录整齐，而是因为它能做到：

- 打开 vault 后知道今天从哪里开始。
- 任一项目都能看到目标、下一步、当前结论。
- 读完 PDF 后能产出自己的永久卡片，而不是只剩摘录。
- 旧项目归档后，知识不会跟着死掉。
- 写方案、写文章、排障时，可以从 MOC 和永久卡片组装，而不是重新搜索。
- 每周都有少量卡片从 `seed` 变成 `connected` 或 `mature`。

## 13. 最小可行版本

如果只做最小改造，先做这 5 件事：

1. 新建 `00-system/00-home.md`。
2. 新建 `05-cards/permanent`、`05-cards/literature`、`05-cards/index`。
3. 给 `01-project/调研PVM` 建项目主页。
4. 给 PVM 建 `MOC - PVM.md`。
5. 从 `闪记.md` 里提炼 10 张永久卡片。

这一步完成后，再考虑全库迁移。先让一个项目跑通，系统才会长出手感。
