---
type: permanent
status: linked
created: 2026-09-04
updated: 2026-09-04
category: 运行模式
summary: PVM 通过软件模拟推进不满足直接执行约束的 Guest，并在条件满足后转换到 PVM mode
sources:
  - "[[pvm_vcpu_run - non-PVM mode 的转换与指令模拟路径]]"
---

# PVM 用 non-PVM mode 承接尚不能直接运行的 Guest 状态

## 观点

PVM 并不要求 Guest 从启动开始就始终满足直接执行条件。对于 32-bit smod 等尚不能进入主要硬件执行路径的状态，PVM 使用 non-PVM mode 作为过渡：先尝试把 Guest 转换到 PVM mode，不能转换时再由 KVM 软件模拟当前指令。

## 依据

源码路径显示，`handle_non_pvm_mode()` 总是先调用 `try_to_convert_to_pvm_mode()`；只有转换失败才进入 `kvm_emulate_instruction()`。

来源：[[pvm_vcpu_run - non-PVM mode 的转换与指令模拟路径]]。

## 适用边界

该结论描述的是 commit `d6bd4cc0fe0e9d4cc136cfd719da135a97f01ba0` 中实现的 non-PVM mode。不同版本支持的模式集合和转换条件需要重新核对。

## 相关

- [[PVM 的 syscall 路径通过 switcher 衔接用户态与 Guest 内核入口]]
- [[PVM switcher 借用 sp0 跨地址空间保留 Guest 退出上下文]]
