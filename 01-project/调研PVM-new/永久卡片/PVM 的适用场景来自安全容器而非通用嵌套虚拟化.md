---
type: permanent
status: linked
created: 2026-08-05
updated: 2026-08-05
summary: 安全容器更重视高性能和强隔离，因此可以放弃通用嵌套虚拟化的完整兼容性
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
  - topic/nested-virtualization
---

# PVM 的适用场景来自安全容器而非通用嵌套虚拟化

## 观点

PVM 能够重新设计嵌套虚拟化路径，是因为安全容器的目标不是运行任意未修改的 L1 hypervisor，而是在任意云底座上获得高性能、强隔离的 L2 运行环境。

## 依据

传统嵌套虚拟化以完整兼容 VMX 语义为目标，L0 必须模拟大量 L1 对硬件虚拟化能力的使用。安全容器可以接受修改 L1 内的软件栈，因此能够以半虚拟化换取更短的执行路径。

来源：[[01-project/调研PVM-new/文献笔记/目前嵌套虚拟化的设计需求并不贴合以IAAS为底座的安全容器的场景|安全容器与通用嵌套虚拟化需求不同]]。

## 适用边界

当 L1 必须运行未经修改的 hypervisor，或者需要完整暴露硬件虚拟化语义时，PVM 的需求裁剪不一定适用。

## 相关

- [[01-project/调研PVM-new/永久卡片/嵌套虚拟化的主要开销来自经 L0 转发的 world switch|嵌套虚拟化的主要开销来自经 L0 转发的 world switch]]
- [[01-project/调研PVM-new/永久卡片/PVM 用软件 switcher 缩短 L1 与 L2 的切换路径|PVM 用软件 switcher 缩短 L1 与 L2 的切换路径]]
