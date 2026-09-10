---
type: literature
status: reading
created: 2026-09-04
updated: 2026-09-04
category: 事件与返回
summary: return-to-user 路径写入 PVM_PVCS_EVENT_VECTOR_STD，但尚未确认事件覆盖保护机制
question: 返回 Guest 用户态之后、下一次 VM-entry 之前的新事件是否会覆盖 PVCS 状态？
---

# PVM_PVCS_EVENT_VECTOR_STD - 返回用户态时的事件覆盖问题

> [!summary]
> `handle_synthetic_instruction_return_user()` 会将 `pvcs->event_vector` 设置为 `PVM_PVCS_EVENT_VECTOR_STD`；在下一次进入 Guest 前到达的新事件是否可能覆盖该状态，当前证据尚不足以回答。

## 要回答的问题

恢复 Guest 用户态上下文后、下一次 VM-entry 前若出现新事件，PVCS 中刚建立的返回上下文会不会被覆盖或丢失？

## 已确认行为

```text
handle_synthetic_instruction_return_user
→ switch_to_umod
→ pvcs->event_vector = PVM_PVCS_EVENT_VECTOR_STD
→ kvm_rip_write(vcpu, pvcs->rip)
→ kvm_rcx_write(vcpu, pvcs->rcx)
→ kvm_r11_write(vcpu, pvcs->r11)
```

## 当前假设

`PVM_PVCS_EVENT_VECTOR_STD` 可能表示下一次进入 Guest 应从标准入口恢复，而不是一个可随意覆盖的普通待注入事件。需要结合事件排队、注入和 VM-entry 前检查路径验证。

## 待验证路径

- [ ] 查找所有写入 `pvcs->event_vector` 的位置。
- [ ] 查找 `PVM_PVCS_EVENT_VECTOR_STD` 的所有读取位置。
- [ ] 确认 VM-entry 前新事件的优先级和排队位置。
- [ ] 确认 PVCS 上下文是否有有效位、嵌套保护或覆盖断言。

## 为什么暂不转永久笔记

这篇笔记目前保存的是明确问题和局部代码证据，还没有形成可验证的结论。完成上述路径检查后，再提炼永久笔记。

## 相关

- [[handle_synthetic_instruction_return_user - 模拟 Guest 返回用户态]]
- [[STD entry_vector.excalidraw|PVM STD event 流程图]]
