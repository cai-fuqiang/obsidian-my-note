---
type: literature
status: reading
created: 2026-09-04
updated: 2026-09-04
category: MMU与地址空间
summary: make_spte 以 host_mmu_root_pgd 是否存在识别 PVM VM，并为 SPTE 设置 shadow_user_mask
question: PVM 的 SPTE 在哪条路径上获得 User 访问权限？
---

# make_spte - PVM 影子页表统一设置 User 权限

> [!summary]
> `make_spte()` 检测到 VM 配置了 `host_mmu_root_pgd` 时，会给生成的 SPTE 增加 `shadow_user_mask`。

## 要回答的问题

PVM 的 SPTE 在哪条路径上获得 User 访问权限？

## 结论

当前代码证据表明，`make_spte()` 使用 `kvm->arch.host_mmu_root_pgd` 是否存在作为条件，为 PVM 的 SPTE 设置 `shadow_user_mask`。

## 调用路径

```text
make_spte
→ if vcpu->kvm->arch.host_mmu_root_pgd
→ spte |= shadow_user_mask
```

## 关键证据

```cpp
if (vcpu->kvm->arch.host_mmu_root_pgd)
    spte |= shadow_user_mask;
```

## 我的理解

这解释了权限位是“在哪里设置的”，但单凭这一处代码还不能完整解释“为什么所有 PVM 影子映射都需要 User 权限”及其安全边界。

## 适用边界与待确认

- [ ] 检查是否存在后续清除或覆盖 `shadow_user_mask` 的路径。
- [ ] 说明 Guest 在 Ring 3 运行与该权限位之间的关系。
- [ ] 分析 Host 模板映射是否也继承相同权限以及如何隔离。

## 可提炼的永久笔记

- [ ] PVM 通过 User 可访问的影子映射支持 Ring 3 Guest 执行

## 相关

- [[host_mmu_root_pgd - 初始化 PVM 顶层影子页表]]
