---
type: literature
status: processed
category: pvm_mmu
summary: host如果使能了PCID在进入Guest前，先设置host_cr3 中的NOFLUSH bit，而在后续Guest trap hypervisor则直接切换到之前设置的host_cr3
created: 2026-09-04T14:50:47+08:00
modified: 2026-09-10T17:36:27+08:00
QA:
  - PVM优化切换过程中为避免TLBflush 做了哪些优化
share_link: https://share.note.sx/evyxoony#q/XaFJ3CjC5Hdkpq2PCrKw
share_updated: 2026-09-10T15:08:52+08:00
---
# summary

> [!summary]
> `= this.summary`

# 引用

## 涉及函数
| 函数                              | 作用                                                                                                             |
| ------------------------------- | -------------------------------------------------------------------------------------------------------------- |
| pvm_set_host_cr3_for_hypervisor | 在切换host 之前保存host_cr3, 此时会host_cr3的具体值要不要置位`PCID_NOFLUSH`(也就是决定从guest_cr3切回host_cr3时，要不要flush guest 地址空间所在的tlb) |
| switcher_return_from_guest      | switcher返回hypervisor的入口函数，其会切换`guest_cr3`->`host_cr3`                                                          |
# details

## pvm_set_host_cr3_for_hypervisor展开
> [!tldr] 相关代码:
> 切换guest之前保存host cr3代码
> ```cpp
> static void pvm_set_host_cr3_for_hypervisor(struct vcpu_pvm *pvm)
> {
> 	unsigned long cr3;
> 
> 	if (static_cpu_has(X86_FEATURE_PCID))
> 		cr3 = __get_current_cr3_fast() | X86_CR3_PCID_NOFLUSH;
> 	else
> 		cr3 = __get_current_cr3_fast();
> 	this_cpu_write(cpu_tss_rw.tss_ex.host_cr3, cr3);
> }
> ```

这样做的好处是vm-exit切换 host 不会flush掉guest 的tlb。

# 适用边界

# related

## 可提炼的永久笔记
- [  ]
## 其他引用笔记

# TODO
- [ ] 为优化 guest-host switch 过程中的tlb flush TLB flush