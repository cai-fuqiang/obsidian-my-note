---
type: literature
status: reading
created: 2026-09-04
updated: 2026-09-04
category: 上下文切换
summary: Guest 从 switcher 退出时 pt_regs 保留在 sp0 栈上，切回 Host CR3 和 Host 栈后再由 PVM 保存
question: Guest 从 switcher 退出到 Host 时，寄存器上下文保存在哪里，何时切换回 Host 栈？
---

# switcher_return_from_guest - 使用 sp0 保留 Guest 退出上下文

> [!summary]
> Guest 在 switcher 中发生异常时，`pt_regs` 保留在 sp0 栈上；代码切换到 Host CR3 和 Host 栈后，将这组寄存器返回给 `pvm_vcpu_run_noinstr()` 保存。

## 要回答的问题

Guest 从 switcher 退出到 Host 时，寄存器上下文保存在哪里，何时切换回 Host 栈？

## 结论

普通 Host userspace 进入内核时，`sync_regs` 会把寄存器复制到当前任务内核栈。Guest 正运行在 switcher 时，`TSS_extra(host_rsp)` 非零，`sync_regs` 直接返回原来的 `eregs`，因此上下文继续位于 sp0。

`switcher_return_from_guest` 先恢复 Host CR3，再把当前 sp0 指针作为返回值保存，随后切换到 `host_rsp` 并恢复 Host callee-saved 寄存器。

## 调用路径

```text
Guest exception
→ error_entry
→ sync_regs
  → host_rsp 非零，直接返回 eregs
→ switcher_return_from_guest
  → 写 Host CR3
  → rax = 当前 rsp（sp0 上的 Guest pt_regs）
  → rsp = host_rsp
  → 恢复 Host 寄存器并 ret
→ pvm_vcpu_run_noinstr
  → ret_regs = switcher_enter_guest()
  → save_regs(vcpu, ret_regs)
```

## 关键证据

```text
switcher_return_from_guest
→ mov host_cr3, %cr3
→ mov %rsp, %rax
→ mov host_rsp, %rsp
→ clear host_rsp
→ restore Host registers
→ ret
```

## 我的理解

sp0 在这条路径中承担临时 Guest 退出帧的角色；Host 栈只保存进入 switcher 前的 Host 调用上下文。两个栈通过 `switcher_enter_guest()` 的返回值衔接。

## 适用边界与待确认

- 当前分析以 `#PF` 异常入口为例。
- [ ] 检查中断、NMI 等入口是否使用相同机制。
- [ ] 补充 `load_sp0()` 与每 CPU entry stack 的准确生命周期。

## 已提炼的永久笔记

- [[PVM switcher 借用 sp0 跨地址空间保留 Guest 退出上下文]]

## 相关

- [[entry_SYSCALL_64_switcher - 将 Guest syscall 上下文保存到 PVCS]]
