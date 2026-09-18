---
created: 2026-09-14T11:20:56+08:00
modified: 2026-09-14T18:02:20+08:00
---

```
@umap_kstack[
    kvm_tdp_mmu_unmap_gfn_range+1
    kvm_unmap_gfn_range+268
    kvm_mmu_notifier_invalidate_range_start+294
    __mmu_notifier_invalidate_range_start+162
    page_vma_mkclean_one.constprop.0+533
    page_mkclean_one+139
    rmap_walk_file+222
    folio_mkclean+161
    folio_clear_dirty_for_io+88
    write_cache_pages+362
    iomap_writepages+52
    ext4_iomap_writepages+169
    do_writepages+109
    __writeback_single_inode+57
    writeback_sb_inodes+539
    __writeback_inodes_wb+76
    wb_writeback+389
    wb_do_writeback+526
    wb_workfn+71
    process_one_work+380
    worker_thread+621
    kthread+201
    ret_from_fork+45
    ret_from_fork_asm+27
]: 4400
```