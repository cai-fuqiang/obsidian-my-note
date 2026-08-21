---
type: moc
status: active
created: 2026-08-05
updated: 2026-08-05
summary: 组织 PVM 的问题背景、软件切换、内存虚拟化、安全边界和性能证据
projects:
  - "[[01-project/调研PVM-new/调研PVM-new|调研PVM-new]]"
areas:
  - "[[虚拟化]]"
mocs: []
sources:
  - "[[01-project/调研PVM-new/文献笔记/SOSP-2023-PVM|SOSP 2023 PVM]]"
output: PVM 为什么用软件重新设计嵌套虚拟化
tags:
  - topic/pvm
  - topic/nested-virtualization
  - signal/output
---

# MOC - PVM

## 我现在如何理解 PVM

PVM 不是试图完整复刻硬件嵌套虚拟化，而是针对安全容器场景缩小需求：让 L1 直接管理 L2 的关键行为，通过软件 switcher 和页表机制减少经 L0 转发的昂贵切换。

## 核心问题

1. 传统嵌套虚拟化为什么在安全容器场景中过重？
2. PVM 如何把 L2 的特权行为交给 L1？
3. software switcher 为什么可能比 VMX 嵌套路径更高效？
4. 分离页表如何同时服务隔离和切换？
5. 影子页表的性能瓶颈在哪里？

## 概念路径

### 问题背景

- [[01-project/调研PVM-new/永久卡片/PVM 的适用场景来自安全容器而非通用嵌套虚拟化|PVM 的适用场景来自安全容器而非通用嵌套虚拟化]]
- [[01-project/调研PVM-new/永久卡片/嵌套虚拟化的主要开销来自经 L0 转发的 world switch|嵌套虚拟化的主要开销来自经 L0 转发的 world switch]]

### CPU 与切换

- [[01-project/调研PVM-new/永久卡片/PVM 用软件 switcher 缩短 L1 与 L2 的切换路径|PVM 用软件 switcher 缩短 L1 与 L2 的切换路径]]

### 隔离与地址空间

- [[01-project/调研PVM-new/永久卡片/PVM 通过分离页表兼顾 L1 与 L2 隔离|PVM 通过分离页表兼顾 L1 与 L2 隔离]]

### 内存虚拟化

- [[01-project/调研PVM-new/永久卡片/SPT-on-EPT 对 GPT2 写保护会放大 world switch|SPT-on-EPT 对 GPT2 写保护会放大 world switch]]

## 文献入口

- [[01-project/调研PVM-new/文献笔记/SOSP-2023-PVM|SOSP 2023 PVM]]
- [[01-project/调研PVM-new/01-PVM introduce|原有 PVM 介绍长文]]
- [[01-project/调研PVM-new/闪记|原始 PDF 闪记]]

## 自动收录

```dataview
TABLE WITHOUT ID
  file.link AS "笔记",
  type AS "类型",
  status AS "状态",
  summary AS "摘要"
FROM "01-project/调研PVM-new"
WHERE contains(mocs, this.file.link) AND file.path != this.file.path
SORT choice(type = "permanent", 1, 2) ASC, file.name ASC
```

## 可输出题目

- PVM 为什么放弃 L1 内的 VMX 嵌套路径？
- 从 world switch 路径理解 PVM 的性能收益。
- PVM 页表隔离与 KPTI 的相似性和差异。

## 空白区

- interrupt virtualization 尚未完成阅读。
- direct switch 的边界条件和异常路径需要结合源码确认。
- 并发 vCPU 下 EPT-on-EPT 扩展性下降的原因仍需实验验证。
