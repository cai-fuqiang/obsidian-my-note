---
type: literature
status: reading
created: 2026-09-04
updated: 2026-09-04
category: syscall
summary: switcher 在 Guest syscall 入口把用户态 CS、EFLAGS、RIP、RCX 和 R11 保存到 PVCS
question: PVM 在 syscall 入口把哪些 Guest 用户态状态保存到了哪里？
modified: 2026-09-04T14:03:24+08:00
---

# entry_SYSCALL_64_switcher - 将 Guest syscall 上下文保存到 PVCS

> [!summary]
> Guest 执行 syscall 后，switcher 将返回 Guest 用户态所需的关键上下文写入 PVCS，包括 CS、EFLAGS、RIP、RCX 和 R11。

## 要回答的问题

PVM 在 syscall 入口把哪些 Guest 用户态状态保存到了哪里？

## 结论

`entry_SYSCALL_64_switcher_safe_stack` 通过 TSS 中的 `pvcs` 指针访问 PVCS，并写入返回 Guest 用户态时需要的上下文。

## 调用路径

```text
entry_SYSCALL_64_switcher
→ entry_SYSCALL_64_switcher_safe_stack
→ TSS_extra(pvcs)
→ PVCS_user_cs / PVCS_eflags / PVCS_rip / PVCS_rcx / PVCS_r11
```

## 关键证据

```asm
movq TSS_extra(pvcs), %rdi
movl $((__USER_DS << 16) | __USER_CS), PVCS_user_cs(%rdi)
movl %r11d, PVCS_eflags(%rdi)
movq %rcx, PVCS_rip(%rdi)
movq %rcx, PVCS_rcx(%rdi)
movq %r11, PVCS_r11(%rdi)
```

## 我的理解

x86-64 `syscall` 会把用户态 RIP 和 RFLAGS 分别放入 RCX、R11。switcher 必须在继续使用这些寄存器之前将原始值持久化到 PVCS，才能在后续返回用户态时重建上下文。

## 适用边界与待确认

- [ ] 原笔记标题称其为 `pvm_vcpu_struct`，需要根据结构定义确认实际所有者是否应表述为 PVCS。
- [ ] 补充源码路径和 revision。

## 可提炼的永久笔记

- [ ] PVM 使用 PVCS 跨 switcher 保存 Guest 用户态返回上下文

## 相关

- [[handle_synthetic_instruction_return_user - 模拟 Guest 返回用户态]]
- [[entry_SYSCALL_64_switcher - 衔接 Guest 用户态与内核 syscall 入口]]
