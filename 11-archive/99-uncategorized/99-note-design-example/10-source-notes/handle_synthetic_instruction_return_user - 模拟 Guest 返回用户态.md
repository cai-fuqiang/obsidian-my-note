---
type: literature
status: reading
created: 2026-09-04
updated: 2026-09-04
category: 事件与返回
summary: Guest 内核不能直接用 iret 返回用户态时，通过约定 syscall 让 KVM 模拟返回流程
question: KVM 如何区分普通 syscall 与用于模拟 Guest iret 的 syscall？
---

# handle_synthetic_instruction_return_user - 模拟 Guest 返回用户态

> [!summary]
> Guest smod 无法直接通过 `iret` 返回用户态时，会在约定位置执行 `syscall`；KVM 根据 `MSR_PVM_RETU_RIP` 识别该合成指令并模拟返回流程。

## 要回答的问题

KVM 如何区分普通 syscall 与用于模拟 Guest `iret` 的 syscall？

## 结论

Guest 通过半虚拟化 MSR `MSR_PVM_RETU_RIP` 告诉 KVM 返回用户态代码的位置。`handle_exit_syscall()` 比较当前 RIP 与 `pvm->msr_retu_rip_plus2`，匹配时进入 `handle_synthetic_instruction_return_user()`。

## 调用路径

```text
Guest smod 返回用户态
→ 在约定位置执行 syscall
→ handle_exit_syscall
→ 比较 rip 与 pvm->msr_retu_rip_plus2
→ handle_synthetic_instruction_return_user
```

## 关键证据

```text
handle_exit_syscall
→ if rip == pvm->msr_retu_rip_plus2
  → handle_synthetic_instruction_return_user
```

## 我的理解

这里的 `syscall` 是 Guest 与 KVM 约定的合成指令载体，而不是普通业务 syscall。MSR 中记录的地址为 KVM 提供了识别标记。

## 适用边界与待确认

- [ ] 补充 `MSR_PVM_RETU_RIP` 的写入、校验及更新时机。
- [ ] 补充返回路径恢复 PVCS 字段的完整顺序。

## 可提炼的永久笔记

- [ ] PVM 用约定 syscall 代替 Guest smod 直接执行 iret

## 相关

- [[PVM_PVCS_EVENT_VECTOR_STD - 返回用户态时的事件覆盖问题]]
- [[entry_SYSCALL_64_switcher - 将 Guest syscall 上下文保存到 PVCS]]
