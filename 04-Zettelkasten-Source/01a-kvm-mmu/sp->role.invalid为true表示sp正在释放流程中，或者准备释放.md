---
type: literature
status: reading
category: kvm_mmu
summary: sp.invalid在sp申请时赋值为false，在释放时赋值为true。但是root_sp因被占用被延迟释放，但是会在首次调用zap函数时，置位invalid。而invalid和`sp->link`行为绑定，当sp没有被释放时，sp->link 挂在 `kvm->arch.active_mmu_pages`, 而当被释放时，在链表移除。invalid始终和该行为保持一致。
created: 2026-09-10T16:02:17+08:00
modified: 2026-09-10T18:51:58+08:00
QA:
  - shadow page 生命周期?
---
# summary

> [!summary]
> `= this.summary`

# 引用

`sp.invaild = 1` 即表示当前`sp` 正在释放流程中，或者等待解除占用后立即被释放，常用于 `root sp`释放。

### 初始化
`sp.invalid` 在sp 申请后，role的很多成员被赋值为`parent_sp->role`， 其中包括 `invalid`:
```
kvm_mmu_get_child_sp
=> role = kvm_mmu_child_role(sptep, direct, access)
   => role = parent_sp->role
   => reinit role.{level, access, direct, passthough...}
=> kvm_mmu_get_shadow_page(,,role)
   => __kvm_mmu_get_shadow_page(,,,,role)
      => kvm_mmu_alloc_shadow_page(,,,,role)
         => sp = kvm_mmu_memory_cache_alloc()
         => sp.role = role
         => list_add(&sp->link, &kvm->arch.active_mmu_pages);
```

> [!faq]  那么在上面的流程中 `sp.invalid` 是不是恒定赋值为0呢?
> 我个人认为是。首先，`root_role` 在赋值时，`invalid` 被[[TODO_dummy_file|赋值为0]]， 其次，[[TODO_dummy_file|当fetch 时，不会从 invalid 的 root sp 遍历]], 另外，`sp.role.invalid` 和 `sp->link` 绑定，`invalid == true` 的sp，一定不在`kvm->arch.active_mmu_pages`所在的链表中。

### change invalid to true
该过程发生在`__kvm_mmu_prepare_zap_page` 函数.
```
__kvm_mmu_prepare_zap_page
=> if (!sp->role.invalid && sp_has_gptes(sp))
   //在该函数中，肯定会将 sp->role.invalid置位，如果该值为true，
   //说明之前走过该函数，已经执行过unaccount
   => unaccount_shadowed(kvm, sp);
//===(1)===
=> if (!sp->root_count)
   => (*nr_zapped)++;
   => if (sp->role.invalid)
      // ===(3)===
      => list_add(&sp->link, invalid_list);
   \> else
      => list_move(&sp->link, invalid_list);
//===(2)===
\> else
   => list_del(&sp->link)
=> sp->role.invalid = 1;
```

* 只要执行到该函数，就一定会将 `sp->role.invalid`置位
* 当`sp->root_count` 不等于0时(`(2)`处)，说明这个`root_sp`还在被某些vcpu使用, 这时将sp从active 链表中移除，并置位`invalid`。等待其执行`kvm_mmu_free_roots->mmu_free_root_page`时，会将 `--sp->root_count` 自减，并再次调用该函数走else分支(`(1)`处)。此时只需要将该sp  执行 `list_add()`而不是`list_move()`。
# related

## 可提炼的永久笔记
- [ ]
## 其他引用笔记

# TODO
* [ ] 🔽  init mmu 时， 对`root_role`的赋值