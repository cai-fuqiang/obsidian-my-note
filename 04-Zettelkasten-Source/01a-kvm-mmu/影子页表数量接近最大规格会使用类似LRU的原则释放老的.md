---
type: literature
status: reading
category: kvm_mmu
summary: 当影子页表申请数量接近最大规格时，会扫描active_mmu_pages 链表，优先释放链表末尾的sp
created: 2026-09-10T17:32:45+08:00
modified: 2026-09-11T15:29:19+08:00
QA:
  - shadow page 生命周期?
---
# summary

> [!summary]
> `= this.summary`

# 引用

调用路径:

```cpp
kvm_mmu_alloc_shadow_page
=> avail = make_mmu_pages_available()
   => if likely(avail >= KVM_MIN_FREE_MMU_PAGES)
      \> return 0
   => kvm_mmu_zap_oldest_mmu_pages(vcpu->kvm, KVM_REFILL_PAGES - avail);
```

当"剩余" mmu pages个数小于`KVM_MIN_FREE_MMU_PAGES`, 会触发mmu pages回收流程。而`mmu_pages` 回收和 内存回收很像，都需要避免工作集抖动。（否则刚释放的页很快又被申请)。但是`mmu_pages` 有没有那么强的回收需求，所以其设计的很简单，回收最早申请的 `shadow page`

`kvm_mmu_zap_oldest_mmu_pages`代码展开:

```cpp
kvm_mmu_zap_oldest_mmu_page
# restart
=> list_for_each_entry_safe_reverse(sp, tmp, &kvm->arch.active_mmu_pages, link)
   //不释放root pages
   => if (sp->root_count)
      => continue
   # 找到要释放的页
   => unstable = __kvm_mmu_prepare_zap_page()
   => total_zapped += nr_zapped;
	  => if (total_zapped >= nr_to_zap)
		 /> break;
	  => if (unstable)
		 /> goto restart;
# 释放页
=> kvm_mmu_commit_zap_page()
```
# related

## 可提炼的永久笔记
- [ ]
## 其他引用笔记

# TODO
* [ ] `__kvm_mmu_prepare_zap_page` 返回值
# TMP
* 