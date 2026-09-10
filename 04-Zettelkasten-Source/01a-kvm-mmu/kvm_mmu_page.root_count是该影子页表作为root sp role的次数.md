---
type: literature
status: reading
category: kvm_mmu
summary: '`kvm_mmu_page.root_count` 记录着该sp作为了几次root_sp, 但是注意该变量不用于tdp_mmu, 其拥有自己的"`root_count`"'
created: 2026-09-10T10:11:07+08:00
modified: 2026-09-10T18:51:59+08:00
QA:
  - kvm_mmu_page.root_count起到什么作用
share_link: https://share.note.sx/bistbrqj#tvLqWSsa/MHbFsJ3ZLSUeA
share_updated: 2026-09-10T15:08:30+08:00
---
# summary

> [!summary]
> `= this.summary`

# 引用

**`sp.root_count`的生命周期**:

在 `mmu_alloc_root` 中会自增该变量:
```sh
mmu_alloc_root
=> ++sp->root_count
```

在`mmu_free_root_page()` 中会自减该变量:

```sh
mmu_alloc_shadow_roots
=> mmu_free_root_page
   => if !(is_tdp_mmu_page())
      \-> if (!--sp->root_count && sp->role.invalid) 
          \-> kvm_mmu_prepare_zap_page()
```
# related

## 可提炼的永久笔记
- [ ]
## 其他引用笔记

# TODO