---
type: literature
status: processed
category: kvm_mmu
summary: 当拿到一个page 或者拿到一个gfn时，可以通过kvm_memory_slot.arch.rmap找到和该page /gfn相关的所有spte
created: 2026-09-09T17:55:39+08:00
modified: 2026-09-10T18:49:29+08:00
QA:
share_link: https://share.note.sx/lz6sxl2p#3bIASIg7XcRvfobm+4qUGg
share_updated: 2026-09-10T15:08:23+08:00
---
# summary

> [!summary]
> `= this.summary`

# 引用

> [!exmaple] 我们以内存回收为例, 来看下如何通过`rmap` 查找要释放的内存，被哪些spte映射了，并clear spte的相关流程: 
> 如果我们回收了一个L2 虚拟机正在使用的内存。会触发下面的流程:

```cpp
kvm_mmu_notifier_invalidate_range_start
=> __kvm_handle_hva_range
   => kvm_mmu_unmap_gfn_range
      => kvm_unmap_gfn_range(kvm, range)
         # 如果该memslots 有rmap， 尝试根据这些rmap解除映射，并释放rmap
         => if (kvm_memslots_have_rmaps(kvm))
            => __kvm_rmap_zap_gfn_range
            
__kvm_rmap_zap_gfn_range
=> __walk_slot_rmaps(,,kvm_zap_rmap,,)
   => kvm_zap_rmap(rmap_head, slots)
      => kvm_zap_all_rmap_sptes()
```

`kvm_zap_all_rmap_spte()`函数 实现:

```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/linux/v7.1-rc3/arch/x86/kvm/mmu/mmu.c"
LINES: "1133-1161"
TITLE: ""
FONT_SIZE: 12
COMMENTS:
  1144: 说明 只有一个rmap对象（只有一个spte指向该 pfn)
  1152: 清除每一个rmap对象
```

`mmu_spte_clear_track_bits` 我们这里仅知道，该函数会`let  spte  present->non-present`即可
界
# related

## 可提炼的永久笔记
- [ ]
## 其他引用笔记

# TODO
* [x] [[kvm_memory_slot.arch.rmap struct | rmap_head 结构图]] ✅ 2026-09-09
* [ ] `mmu_spte_clear_track_bits()` 细节