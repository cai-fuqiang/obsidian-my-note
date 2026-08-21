---
type: literature
status: processed
created: 2026-08-05
updated: 2026-08-05
summary: PVM 面向安全容器缩小嵌套虚拟化需求，用软件切换和影子页表减少 L0 参与
source_url:
citekey: sosp2023-pvm
authors: []
published: 2023
projects:
  - "[[01-project/调研PVM-new/调研PVM-new|调研PVM-new]]"
areas:
  - "[[虚拟化]]"
mocs:
  - "[[01-project/调研PVM-new/MOC/MOC - PVM|MOC - PVM]]"
sources: []
tags:
  - topic/pvm
  - topic/nested-virtualization
  - activity/code-reading
---

# SOSP 2023 PVM

本地 PDF：[[01-project/调研PVM-new/pdf/sosp2023-pvm-paper.pdf|sosp2023-pvm-paper.pdf]]

## 一句话

PVM 针对云上安全容器重新定义嵌套虚拟化需求，在不修改 L0 KVM 的前提下，由 L1 使用软件 switcher 和影子页表直接管理 L2。

## 为什么读

- 理解传统嵌套虚拟化的主要性能开销。
- 理解 PVM 为什么主动避开 L1 中的 VMX 嵌套路径。
- 为后续 PVM 源码走读建立设计地图。

## 核心结论

1. 传统嵌套虚拟化中，L2 的事件经常先进入 L0，再由 L0 转交 L1，放大 world switch 成本。
2. 安全容器不需要通用嵌套虚拟化的全部兼容性，可以通过半虚拟化缩小设计范围。
3. PVM 把 L2 user 和 kernel 放在 L1 的非特权级，由 L1 捕获其特权行为。
4. switcher 保存和恢复上下文，并处理 L2 与 L1、L2 user 与 kernel 之间的切换。
5. PVM 使用分离页表和软件影子页表，在隔离、安全和性能之间取平衡。

## 阅读地图

- [[01-project/调研PVM-new/文献笔记/PVM概述|PVM 概述]]
- [[01-project/调研PVM-new/文献笔记/PVM 设计简述|PVM 设计简述]]
- [[01-project/调研PVM-new/文献笔记/PVM目标- 轻量, 简单，高效|PVM 目标]]
- [[01-project/调研PVM-new/文献笔记/PVM switch what|switcher 切换什么]]
- [[01-project/调研PVM-new/文献笔记/PVM为不同角色使用不同页表提升安全性|分离页表]]
- [[01-project/调研PVM-new/文献笔记/内存嵌套虚拟化两种实现性能均不佳|嵌套内存虚拟化开销]]
- [[01-project/调研PVM-new/文献笔记/SPT readonly是导致一阶段world switch 主要因素|GPT2 写保护开销]]

## 我的理解

PVM 的关键不是“软件一定比硬件快”，而是它改变了事件处理路径。对于 L1 与 L2 频繁交互的安全容器负载，避免无意义地经过 L0，可能比复用完整 VMX 语义更重要。

## 待确认问题

- [ ] direct switch 能处理哪些 syscall、异常和中断，哪些仍必须进入 L1 hypervisor？
- [ ] 并发 vCPU 下，PVM 的影子页表锁竞争如何控制？
- [ ] PVM 的安全边界与标准 KVM nested virtualization 相比有哪些变化？

## 待转永久卡片

- [ ] PVM 的 parallel SPT 如何降低并发更新冲突
- [ ] pre-fault 如何减少 guest page fault 路径成本

## 已转永久卡片

- [[01-project/调研PVM-new/永久卡片/PVM 的适用场景来自安全容器而非通用嵌套虚拟化|PVM 的适用场景来自安全容器而非通用嵌套虚拟化]]
- [[01-project/调研PVM-new/永久卡片/嵌套虚拟化的主要开销来自经 L0 转发的 world switch|嵌套虚拟化的主要开销来自经 L0 转发的 world switch]]
- [[01-project/调研PVM-new/永久卡片/PVM 用软件 switcher 缩短 L1 与 L2 的切换路径|PVM 用软件 switcher 缩短 L1 与 L2 的切换路径]]
- [[01-project/调研PVM-new/永久卡片/PVM 通过分离页表兼顾 L1 与 L2 隔离|PVM 通过分离页表兼顾 L1 与 L2 隔离]]
- [[01-project/调研PVM-new/永久卡片/SPT-on-EPT 对 GPT2 写保护会放大 world switch|SPT-on-EPT 对 GPT2 写保护会放大 world switch]]
