---
type: permanent
status: linked
created: 2026-08-05
updated: 2026-08-05
summary: PVM 用共享映射的软件 switcher 保存恢复上下文，使常见 L1/L2 切换不必经 L0 转发
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
  - topic/kvm
---

# PVM 用软件 switcher 缩短 L1 与 L2 的切换路径

## 观点

PVM 的 software switcher 不是对 VMX 的逐指令模拟，而是一段负责保存和恢复上下文的精简切换机制。它让 L2 的特权行为直接进入 L1 管理路径，避免常见事件先退出到 L0 再被转发回来。

## 依据

switcher 包含精简汇编和每 CPU 数据结构，负责两类切换：L1 hypervisor 与 L2 之间的 world switch，以及 L2 user 与 kernel 之间的 guest ring switch。

来源：[[01-project/调研PVM-new/文献笔记/PVM switch what|switcher 切换什么]]、[[01-project/调研PVM-new/文献笔记/switcher 组成包括高效简洁的汇编代码和数据结构|switcher 的组成]]。

## 适用边界

direct switch 只适用于 switcher 能够独立处理的路径。需要完整设备模拟、复杂中断处理或 hypervisor 服务的事件仍可能进入 L1 hypervisor。

## 相关

- [[01-project/调研PVM-new/永久卡片/嵌套虚拟化的主要开销来自经 L0 转发的 world switch|嵌套虚拟化的主要开销来自经 L0 转发的 world switch]]
- [[01-project/调研PVM-new/永久卡片/PVM 通过分离页表兼顾 L1 与 L2 隔离|PVM 通过分离页表兼顾 L1 与 L2 隔离]]
