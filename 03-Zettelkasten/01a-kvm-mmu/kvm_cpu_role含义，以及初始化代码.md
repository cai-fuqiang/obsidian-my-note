---
modified: 2026-09-15T21:49:15+08:00
---
> [!summary]  `kvm_cpu_role`
> `role`的含义是角色的意思，而`mmu.cpu_role` 表示 `vcpu mmu`，所代表的角色。而描述一个角色/身份需要一些属性。`kvm_vcpu_role`即描述 `vcpu mmu` 的一些行为属性。而 `vcpu mmu` 的行为由什么控制呢? 往往有一些控制寄存器/MSR控制(cr0, cr4, efer)， 例如cr0 控制保护模式开启，而cr4控制pcid。

`kvm_vcpu_role` 赋值流程, 只在 初始化/重新初始化 `kvm_mmu` 时调用.

```cpp
kvm_init_mmu
=> cpu_role = kvm_calc_cpu_role(vcpu, &regs)
```

# 附录
## `____is_cr4_smep` 宏定义

```cpp
#define BUILD_MMU_ROLE_REGS_ACCESSOR(reg, name, flag)			\
static inline bool __maybe_unused					\
____is_##reg##_##name(const struct kvm_mmu_role_regs *regs)		\
{									\
	return !!(regs->reg & flag);					\
}
...
BUILD_MMU_ROLE_REGS_ACCESSOR(cr4, smep, X86_CR4_SMEP);
```