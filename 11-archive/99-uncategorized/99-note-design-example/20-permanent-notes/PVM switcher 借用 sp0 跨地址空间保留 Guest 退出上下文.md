---
type: permanent
status: linked
created: 2026-09-04
updated: 2026-09-04
category: 上下文切换
summary: PVM 将 Guest 异常退出帧暂存在 sp0 栈上，恢复 Host 地址空间和栈后再保存到 vCPU
sources:
  - "[[switcher_return_from_guest - 使用 sp0 保留 Guest 退出上下文]]"
---

# PVM switcher 借用 sp0 跨地址空间保留 Guest 退出上下文

## 观点

PVM 从 Guest switcher 退出时，不能立刻依赖普通 Host 任务栈保存寄存器。异常入口先让 Guest `pt_regs` 留在 sp0 指向的每 CPU 入口栈中；恢复 Host CR3 和 Host 栈后，再把这组寄存器交给 `pvm_vcpu_run_noinstr()` 保存到 vCPU。

## 依据

`sync_regs` 通过 `TSS_extra(host_rsp)` 判断当前是否位于 switcher。处于 switcher 时它直接保留原 `eregs`。`switcher_return_from_guest` 把当前 sp0 指针作为返回值，同时切换 CR3 和 RSP，最后由调用者执行 `save_regs()`。

来源：[[switcher_return_from_guest - 使用 sp0 保留 Guest 退出上下文]]。

## 适用边界

当前证据来自 `#PF` 等常规异常入口。NMI、双重错误和其他特殊入口是否完全相同，需要单独验证。

## 相关

- [[PVM 的 syscall 路径通过 switcher 衔接用户态与 Guest 内核入口]]
- [[PVM 在顶层影子页表中复制 Host MMU 根页表模板]]
