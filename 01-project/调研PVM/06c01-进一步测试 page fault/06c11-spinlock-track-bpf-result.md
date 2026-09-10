---
created: 2026-09-08T10:23:53+08:00
modified: 2026-09-10T11:03:14+08:00
share_link: https://share.note.sx/7s1c8iow#p0vysG9Nop4Lj9su+DCFMQ
share_updated: 2026-09-10T11:02:47+08:00
---
# L0
```python
@spinlock_count[pf_trigger]: 1603182
@spinlock_stack[
    native_queued_spin_lock_slowpath+1
    _raw_spin_lock_irqsave+38
    folio_lruvec_lock_irqsave+95
    folio_batch_move_lru+90
    lru_add_drain_cpu+124
    lru_add_drain+17
    vms_clear_ptes.part.0+76
    vms_complete_munmap_vmas+304
    do_vmi_align_munmap+439
    do_vmi_munmap+204
    __vm_munmap+161
    __x64_sys_munmap+23
    do_syscall_64+91
    entry_SYSCALL_64_after_hwframe+118
]: 88571

@spinlock_stack[
    native_queued_spin_lock_slowpath+1
    _raw_spin_lock_irqsave+38
    folio_lruvec_lock_irqsave+95
    __page_cache_release.part.0+88
    folios_put_refs+488
    free_pages_and_swap_cache+355
    __tlb_batch_free_encoded_pages+62
    tlb_finish_mmu+117
    vms_clear_ptes.part.0+273
    vms_complete_munmap_vmas+304
    do_vmi_align_munmap+439
    do_vmi_munmap+204
    __vm_munmap+161
    __x64_sys_munmap+23
    do_syscall_64+91
    entry_SYSCALL_64_after_hwframe+118
]: 180919

@spinlock_stack[
    native_queued_spin_lock_slowpath+1
    _raw_spin_lock_irqsave+38
    folio_lruvec_lock_irqsave+95
    __page_cache_release.part.0+88
    folios_put_refs+488
    free_pages_and_swap_cache+210
    __tlb_batch_free_encoded_pages+62
    tlb_finish_mmu+117
    vms_clear_ptes.part.0+273
    vms_complete_munmap_vmas+304
    do_vmi_align_munmap+439
    do_vmi_munmap+204
    __vm_munmap+161
    __x64_sys_munmap+23
    do_syscall_64+91
    entry_SYSCALL_64_after_hwframe+118
]: 758369

@spinlock_stack[
    native_queued_spin_lock_slowpath+1
    _raw_spin_lock_irqsave+38
    folio_lruvec_lock_irqsave+95
    folio_batch_move_lru+90
    __folio_batch_add_and_move+125
    do_anonymous_page+1043
    __handle_mm_fault+756
    handle_mm_fault+393
    do_user_addr_fault+475
    exc_page_fault+98
    asm_exc_page_fault+45
]: 575141

@time_hist:
[256, 512)        439996 |@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@   |
[512, 1K)         230033 |@@@@@@@@@@@@@@@@@@@@@@@@@@                          |
[1K, 2K)          337953 |@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@              |
[2K, 4K)          458511 |@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@|
[4K, 8K)          135542 |@@@@@@@@@@@@@@@                                     |
[8K, 16K)           1144 |                                                    |
[16K, 32K)             3 |                                                    |
```

# L1

```
@spinlock_count[pf_trigger]: 2389526
@spinlock_stack[
    handshake_exit+801137390
    handshake_exit+801137390
    multiport_mt_exit+40182
    __pv_queued_spin_lock_slowpath+5
    _raw_spin_lock_irqsave+38
    folio_lruvec_lock_irqsave+91
    __page_cache_release.part.0+88
    folios_put_refs+228
    folio_batch_move_lru+227
    folio_add_lru+77
    do_anonymous_page+1193
    __handle_mm_fault+745
    handle_mm_fault+430
    exc_page_fault+492
    asm_exc_page_fault+34
]: 126588
@spinlock_stack[
    handshake_exit+801137390
    handshake_exit+801137390
    multiport_mt_exit+40182
    __pv_queued_spin_lock_slowpath+5
    _raw_spin_lock_irqsave+38
    folio_lruvec_lock_irqsave+91
    __page_cache_release.part.0+88
    folios_put_refs+228
    free_pages_and_swap_cache+372
    tlb_flush_mmu+216
    tlb_finish_mmu+61
    unmap_region.constprop.0+318
    do_vmi_align_munmap+919
    do_vmi_munmap+257
    __vm_munmap+184
    __x64_sys_munmap+23
    do_syscall_64+85
    entry_SYSCALL_64_after_hwframe+120
]: 135077
@spinlock_stack[
    handshake_exit+801137390
    handshake_exit+801137390
    multiport_mt_exit+40182
    __pv_queued_spin_lock_slowpath+5
    _raw_spin_lock_irqsave+38
    folio_lruvec_lock_irqsave+91
    __page_cache_release.part.0+88
    folios_put_refs+228
    free_pages_and_swap_cache+220
    tlb_flush_mmu+216
    tlb_finish_mmu+61
    unmap_region.constprop.0+318
    do_vmi_align_munmap+919
    do_vmi_munmap+257
    __vm_munmap+184
    __x64_sys_munmap+23
    do_syscall_64+85
    entry_SYSCALL_64_after_hwframe+120
]: 1047052
@spinlock_stack[
    handshake_exit+801137390
    handshake_exit+801137390
    multiport_mt_exit+40182
    __pv_queued_spin_lock_slowpath+5
    _raw_spin_lock_irqsave+38
    folio_lruvec_lock_irqsave+91
    folio_batch_move_lru+91
    folio_add_lru+77
    do_anonymous_page+1193
    __handle_mm_fault+745
    handle_mm_fault+430
    exc_page_fault+492
    asm_exc_page_fault+34
]: 1080553

@time_hist:
[128, 256)           582 |                                                    |
[256, 512)           898 |                                                    |
[512, 1K)            491 |                                                    |
[1K, 2K)            1023 |                                                    |
[2K, 4K)            1995 |                                                    |
[4K, 8K)           14364 |                                                    |
[8K, 16K)         670133 |@@@@@@@@@@@@@@@@@@@@                                |
[16K, 32K)       1686550 |@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@|
[32K, 64K)         13473 |                                                    |
[64K, 128K)           10 |                                                    |
[128K, 256K)           7 |                                                    |
```