---
type: permanent
status: seed
created: 2026-08-05
updated: 2026-08-05
summary: 为同步影子页表而写保护 GPT2，会让一次多级页表更新触发多轮 L2、L0、L1 切换
projects:
  - "[[01-project/调研PVM-new/调研PVM-new|调研PVM-new]]"
areas:
  - "[[虚拟化]]"
mocs:
  - "[[01-project/调研PVM-new/MOC/MOC - PVM|MOC - PVM]]"
sources:
  - "[[01-project/调研PVM-new/文献笔记/SOSP-2023-PVM|SOSP 2023 PVM]]"
tags:
  - topic/mmu
  - topic/nested-virtualization
  - signal/review
---

# SPT-on-EPT 对 GPT2 写保护会放大 world switch

## 观点

SPT-on-EPT 为捕获 GPT2 更新而对其写保护。L2 修改页表时，每个需要写入的页表层级都可能触发缺页处理，并沿 L2 -> L0 -> L1 的路径产生多轮 world switch。

## 依据

影子页表必须跟随 GPT2 的映射变化。将 GPT2 所在页面写保护后，L2 page fault handler 在建立多级页表时，对不同层级页表项的写入都可能需要 L1 协助。

来源：[[01-project/调研PVM-new/文献笔记/SPT readonly是导致一阶段world switch 主要因素|GPT2 写保护导致多轮切换]]。

## 适用边界

实际切换次数取决于页表层级、已有映射和本次缺页需要补齐的层级，并非每次都达到最坏情况。该卡片仍需结合实验数据复核，因此暂时保持 `seed`。

## 相关

- [[01-project/调研PVM-new/永久卡片/嵌套虚拟化的主要开销来自经 L0 转发的 world switch|嵌套虚拟化的主要开销来自经 L0 转发的 world switch]]
- [[01-project/调研PVM-new/永久卡片/PVM 通过分离页表兼顾 L1 与 L2 隔离|PVM 通过分离页表兼顾 L1 与 L2 隔离]]
