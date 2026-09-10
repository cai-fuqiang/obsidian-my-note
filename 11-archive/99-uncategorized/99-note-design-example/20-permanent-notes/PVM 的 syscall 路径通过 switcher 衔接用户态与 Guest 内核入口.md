---
type: permanent
status: linked
created: 2026-09-04
updated: 2026-09-04
category: syscall
summary: PVM 的 Guest syscall 先进入共享 switcher 保存切换状态，再进入专用 Guest 内核入口
sources:
  - "[[entry_SYSCALL_64_switcher - 衔接 Guest 用户态与内核 syscall 入口]]"
  - "[[entry_SYSCALL_64_switcher - 将 Guest syscall 上下文保存到 PVCS]]"
modified: 2026-09-04T13:51:07+08:00
---

# PVM 的 syscall 路径通过 switcher 衔接用户态与 Guest 内核入口

## 观点

PVM 中的 Guest 用户态到 Guest 内核态切换不是直接进入普通内核 syscall 入口。Guest 首先进入共享的 `entry_SYSCALL_64_switcher`，保存跨地址空间切换所需的用户态上下文，再进入 `entry_SYSCALL_64_pvm`。

## 依据

两个入口承担不同角色：switcher 入口负责切换准备，PVM 入口负责进入 Guest 内核。switcher 会把 syscall 自动写入 RCX、R11 的原始返回状态以及 CS 信息保存到 PVCS。

来源：[[entry_SYSCALL_64_switcher - 衔接 Guest 用户态与内核 syscall 入口]]、[[entry_SYSCALL_64_switcher - 将 Guest syscall 上下文保存到 PVCS]]。

## 适用边界

该卡片只描述 64 位 Guest syscall 入口。32 位兼容模式、异常和中断使用的入口需要分别分析。

## 相关

- [[PVM switcher 借用 sp0 跨地址空间保留 Guest 退出上下文]]
- [[PVM 用 non-PVM mode 承接尚不能直接运行的 Guest 状态]]
