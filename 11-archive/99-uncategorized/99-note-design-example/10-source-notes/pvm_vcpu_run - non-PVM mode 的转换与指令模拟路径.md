---
type: literature
status: processed
created: 2026-09-04
updated: 2026-09-04
category: 运行模式
summary: non-PVM VM-exit 先尝试转换为 PVM mode，不能转换时才软件模拟当前指令
revision: d6bd4cc0fe0e9d4cc136cfd719da135a97f01ba0
---

# pvm_vcpu_run - non-PVM mode 的转换与指令模拟路径

> [!summary]
> Guest 处于 non-PVM mode 时，KVM 不会进入常规 PVM 硬件执行路径；它先判断当前状态能否转换为 PVM mode，只有不能转换时才软件模拟当前指令。

## 要回答的问题

PVM 如何运行尚不满足 PVM mode 约束的 Guest 状态？

## 结论

PVM mode 包括 64-bit smod、64-bit umod 和 32-bit umod；32-bit smod 等状态属于 non-PVM mode。后者主要出现在 vCPU bring-up 等过渡阶段。

`handle_non_pvm_mode()` 先调用 `try_to_convert_to_pvm_mode()`。转换成功后，当前指令可以回到 Guest 中直接执行；转换失败时，KVM 才调用指令模拟器。

## 调用路径

```text
vcpu_enter_guest
→ pvm_vcpu_run
  → non_pvm_mode 时返回 EXIT_FASTPATH_NONE
→ pvm_handle_exit_irqoff
→ pvm_handle_exit
→ handle_non_pvm_mode
  → try_to_convert_to_pvm_mode
  → kvm_emulate_instruction
```

## 关键证据

```cpp
handle_non_pvm_mode
=> if (try_to_convert_to_pvm_mode(vcpu))
   => return 1
=> ret = kvm_emulate_instruction(vcpu, 0)
```

`pvm_vcpu_reset()` 会将 `non_pvm_mode` 初始化为真；模式转换还可能发生在处理 non-PVM VM-exit、PVM event 以及设置 segment 的路径中。

## 我的理解

non-PVM mode 是一个兼容性过渡层，而不是 PVM 的主要执行模式。它让 Guest 在状态尚未标准化时仍能继续推进，并在满足约束后尽快回到直接硬件执行路径。

## 适用边界与待确认

- 已知依据对应 commit `d6bd4cc0fe0e9d4cc136cfd719da135a97f01ba0`。
- [ ] 补充源码仓库 URL 和准确文件路径。
- [ ] 枚举阻止 `try_to_convert_to_pvm_mode()` 成功的具体状态。

## 已提炼的永久笔记

- [[PVM 用 non-PVM mode 承接尚不能直接运行的 Guest 状态]]

## 相关

- [[entry_SYSCALL_64_switcher - 衔接 Guest 用户态与内核 syscall 入口]]
