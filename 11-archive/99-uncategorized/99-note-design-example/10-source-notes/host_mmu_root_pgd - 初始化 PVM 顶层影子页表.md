---
type: literature
status: reading
created: 2026-09-04
updated: 2026-09-04
category: MMU与地址空间
summary: PVM 创建顶层影子页表时复制 host_mmu_root_pgd，LA57 下还需处理 PGD 511 指向的 P4D
question: Guest 新建顶层影子页表时，PVM 如何放入切换所需的 Host 地址映射？
---

# host_mmu_root_pgd - 初始化 PVM 顶层影子页表

> [!summary]
> PVM 在创建 Guest CR3 对应的顶层影子页表时，以 `host_mmu_root_pgd` 为模板复制 Host 映射；Host 使用 LA57 时还需要处理 `PGD[511]` 指向的 P4D。

## 要回答的问题

Guest 新建顶层影子页表时，PVM 如何放入 switcher 所需的 Host 地址映射？

## 结论

`pvm_vm_init()` 将全局 `host_mmu_root_pgd` 保存到 VM 架构数据中。分配 `HOST_ROOT_LEVEL` 的影子页时，KVM 将整页根表复制到新的 SPT。

四级页表只需要复制 PGD；五级页表的保留空间跨越两个层级，因此还要识别并复制 `PGD[511]` 指向的 P4D。

## 调用路径

```text
kvm_arch_init_vm
→ pvm_vm_init
→ kvm->arch.host_mmu_root_pgd = host_mmu_root_pgd

kvm_mmu_get_child_sp
→ kvm_mmu_get_shadow_page
→ __kvm_mmu_get_shadow_page
→ kvm_mmu_alloc_shadow_page
→ memcpy(sp->spt, kvm->arch.host_mmu_root_pgd, PAGE_SIZE)
```

## 关键证据

```cpp
if (kvm->arch.host_mmu_root_pgd && role.level == HOST_ROOT_LEVEL)
    memcpy(sp->spt, kvm->arch.host_mmu_root_pgd, PAGE_SIZE);
```

LA57 下的额外识别条件：

```text
pvm_mmu_p4d_at_la57_pgd511
→ pgtable_l5_enable
→ kvm->arch.host_mmu_root_pgd
→ parent role.level == 5
→ spte_index(sptep) == 511
```

## 我的理解

`host_mmu_root_pgd` 并不是 Guest 常规页表内容，而是新建 PVM 顶层影子页表时使用的初始化模板。复制动作让多个 Guest 地址空间都具有切换路径所需的固定映射。

## 适用边界与待确认

- 这里只描述 PVM 启用 `host_mmu_root_pgd` 的路径。
- [ ] 补充四级和五级页表保留区间的源码定义。
- [ ] 确认被复制映射的权限以及 Guest 可见边界。

## 已提炼的永久笔记

- [[PVM 在顶层影子页表中复制 Host MMU 根页表模板]]

## 相关

- [[make_spte - PVM 影子页表统一设置 User 权限]]
- [[100-cr3_and_address_space.excalidraw|PVM CR3 与地址空间图]]
