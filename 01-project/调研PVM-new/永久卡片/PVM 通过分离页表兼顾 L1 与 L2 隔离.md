---
type: permanent
status: linked
created: 2026-08-05
updated: 2026-08-05
summary: PVM 为 L1、L2 user 和 L2 kernel 使用不同页表，只共享 switcher 必需的每 CPU 入口区
projects:
  - "[[01-project/调研PVM-new/调研PVM-new|调研PVM-new]]"
areas:
  - "[[虚拟化]]"
mocs:
  - "[[01-project/调研PVM-new/MOC/MOC - PVM|MOC - PVM]]"
sources:
  - "[[01-project/调研PVM-new/文献笔记/SOSP-2023-PVM|SOSP 2023 PVM]]"
tags:
  - topic/pvm
  - topic/mmu
---

# PVM 通过分离页表兼顾 L1 与 L2 隔离

## 观点

PVM 并非让 L1 与 L2 共用完整地址空间。它为 L1 host kernel、L2 guest user 和 L2 guest kernel 使用不同页表，只把切换所需的代码和数据映射到共同的每 CPU 入口区。

## 依据

这种设计类似 KPTI：不同角色的大部分地址空间相互隔离，而 syscall 入口、IDT、TSS、trampoline stack 和 switcher 状态等切换必需内容保持固定映射。

来源：[[01-project/调研PVM-new/文献笔记/PVM为不同角色使用不同页表提升安全性|PVM 分离页表的设计]]。

## 适用边界

共享入口区仍然属于跨地址空间可见面，需要严格控制其代码、数据和更新方式；分离页表降低暴露范围，但不自动消除所有侧信道风险。

## 相关

- [[01-project/调研PVM-new/永久卡片/PVM 用软件 switcher 缩短 L1 与 L2 的切换路径|PVM 用软件 switcher 缩短 L1 与 L2 的切换路径]]
- [[01-project/调研PVM-new/永久卡片/SPT-on-EPT 对 GPT2 写保护会放大 world switch|SPT-on-EPT 对 GPT2 写保护会放大 world switch]]
