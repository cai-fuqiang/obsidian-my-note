---
type: literature
status: reading
created: 2026-09-04
updated: 2026-09-04
category: syscall
summary: Guest 用户态 syscall 先进入共享 switcher，再由 PVM 专用入口进入 Guest 内核
question: entry_SYSCALL_64_switcher 与 entry_SYSCALL_64_pvm 分别位于 syscall 路径的哪一段？
modified: 2026-09-04T13:57:15+08:00
---

# entry_SYSCALL_64_switcher - 衔接 Guest 用户态与内核 syscall 入口

> [!summary]
> `entry_SYSCALL_64_switcher` 是 Guest 用户态首先到达的共享入口，`entry_SYSCALL_64_pvm` 则是随后进入 Guest 内核的 PVM syscall 入口。

## 要回答的问题

`entry_SYSCALL_64_switcher` 与 `entry_SYSCALL_64_pvm` 分别位于 syscall 路径的哪一段？

## 结论

- `entry_SYSCALL_64_switcher`：Guest 用户态执行 `syscall` 后进入的 switcher 入口。
- `entry_SYSCALL_64_pvm`：switcher 完成必要处理后进入 Guest kernel 的入口。

## 调用路径

```text
Guest userspace
→ syscall
→ entry_SYSCALL_64_switcher
→ entry_SYSCALL_64_pvm
→ Guest kernelspace
```

## 关键证据

当前笔记只确认了两个入口的相对角色，尚未补齐中间跳转指令和所在源码文件。

## 我的理解

这两个入口的区分说明 PVM 的 syscall 路径包含一个跨地址空间共享的切换阶段，不能把 Guest 用户态到 Guest 内核态理解为普通 Linux syscall 的单一入口。

## 适用边界与待确认

- [ ] 补充两个入口的源码路径和 revision。
- [ ] 确认 switcher 在进入 `entry_SYSCALL_64_pvm` 前保存和修改了哪些状态。

## 已提炼的永久笔记

- [[PVM 的 syscall 路径通过 switcher 衔接用户态与 Guest 内核入口]]

## 相关

- [[entry_SYSCALL_64_switcher - 将 Guest syscall 上下文保存到 PVCS]]
- [[handle_synthetic_instruction_return_user - 模拟 Guest 返回用户态]]
