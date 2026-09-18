---
type: literature
status: processed
category: pvm_mmu
summary: PVM在fill spte时，始终置位shadow_user_mask
created: 2026-09-04T15:30:22+08:00
modified: 2026-09-17T18:25:02+08:00
QA:
  - PVM是如何做到Guest/Host 页表隔离
share_link: https://share.note.sx/sf05h8rm#1JAGfiNQaaQlN3ycmSzHaA
share_updated: 2026-09-10T15:08:49+08:00
---
# summary

> [!summary]
> `= this.summary`

# 引用

调用链:

```cpp
make_spte
=> if vcpu->kvm->arch.host_mmu_root_pgd
   => spte |= shadow_user_mask
```

# 适用边界

# related

## 可提炼的永久笔记
- [ ]
## 其他引用笔记

# TODO