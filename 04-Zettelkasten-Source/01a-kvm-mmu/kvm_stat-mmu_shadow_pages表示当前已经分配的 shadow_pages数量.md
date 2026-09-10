---
type: literature
status: reading
category: kvm_mmu
summary: 表示已分配的shadow pages数量，随着shadow page的生命周期变动而自增自减
created: 2026-09-10T15:12:26+08:00
modified: 2026-09-10T18:51:58+08:00
QA:
  - 怎么获取当前已经分配的shadow pages?
---
# summary

> [!summary]
> `= this.summary`

# 引用
既然 `mmu_shadow_pages` 表示当前已经分配的`shadow_pages` 数量, 所以该stat和shadow pages生命周期强相关
* stat 增 -- 申请 shadow pages
```
kvm_mmu_alloc_shadow_page
=> kvm_account_mmu_page()
   => kvm->stat.mmu_shadow_pages++
```

* stat 减 -- 释放 shadow  pages
```
__kvm_mmu_prepare_zap_page
=> kvm_unaccount_mmu_page
   => kvm->stat.mmu_shadow_pages--;
```
# related

## 可提炼的永久笔记
- [ ]
## 其他引用笔记

# TODO