---
type: permanent
status: linked
created: 2026-08-05
updated: 2026-08-05
summary: L2 事件需要经 L0 转交 L1，使一次逻辑处理产生多次昂贵的上下文切换
projects:
  - "[[01-project/调研PVM-new/调研PVM-new|调研PVM-new]]"
areas:
  - "[[虚拟化]]"
mocs:
  - "[[01-project/调研PVM-new/MOC/MOC - PVM|MOC - PVM]]"
sources:
  - "[[01-project/调研PVM-new/文献笔记/SOSP-2023-PVM|SOSP 2023 PVM]]"
tags:
  - topic/kvm
  - topic/nested-virtualization
---

# 嵌套虚拟化的主要开销来自经 L0 转发的 world switch

## 观点

传统嵌套虚拟化的关键成本不只是 VM-exit 本身，而是 L2 事件往往先进入 L0，再被转交给 L1 处理；L1 恢复 L2 时又需要经过 L0，从而把一次逻辑处理放大为多次 world switch。

## 依据

L2 的 VM-exit 首先到达 VMX root operation 中的 L0。若事件应由 L1 处理，L0 需要构造状态并进入 L1；L1 完成模拟后执行的恢复操作又会退出到 L0，最终由 L0 恢复 L2。

来源：[[01-project/调研PVM-new/01-PVM introduce#nested virtialization|原有嵌套虚拟化路径分析]]。

## 适用边界

shadow VMCS 等硬件能力能够减少部分 VMREAD、VMWRITE 退出，但不能消除 L1 与 L2 切换必须经 L0 转发这一基础路径。

## 相关

- [[01-project/调研PVM-new/永久卡片/PVM 用软件 switcher 缩短 L1 与 L2 的切换路径|PVM 用软件 switcher 缩短 L1 与 L2 的切换路径]]
- [[01-project/调研PVM-new/永久卡片/SPT-on-EPT 对 GPT2 写保护会放大 world switch|SPT-on-EPT 对 GPT2 写保护会放大 world switch]]
