---
type: permanent
status: linked
created: 2026-09-04
updated: 2026-09-04
category: MMU与地址空间
summary: PVM 新建顶层影子页表时复制 Host 根页表模板，使切换所需映射出现在 Guest 地址空间
sources:
  - "[[host_mmu_root_pgd - 初始化 PVM 顶层影子页表]]"
---

# PVM 在顶层影子页表中复制 Host MMU 根页表模板

## 观点

PVM 在创建 Guest CR3 对应的顶层影子页表时，不是从完全空白的根表开始，而是复制 `host_mmu_root_pgd`。这样，每个相关地址空间在创建之初就具备 PVM 切换路径需要的固定 Host 映射。

## 依据

PVM VM 初始化时保存全局 `host_mmu_root_pgd`；KVM 分配 `HOST_ROOT_LEVEL` 的影子页时，将该根表复制到新 SPT。Host 使用五级页表时，还需要额外复制 `PGD[511]` 指向的 P4D。

来源：[[host_mmu_root_pgd - 初始化 PVM 顶层影子页表]]。

## 适用边界

这一结论只适用于配置了 `kvm->arch.host_mmu_root_pgd` 的 PVM VM。复制进 Guest 地址空间的具体范围、权限以及安全边界应以对应版本的页表布局为准。

## 相关

- [[PVM switcher 借用 sp0 跨地址空间保留 Guest 退出上下文]]
- [[100-cr3_and_address_space.excalidraw|PVM CR3 与地址空间图]]
