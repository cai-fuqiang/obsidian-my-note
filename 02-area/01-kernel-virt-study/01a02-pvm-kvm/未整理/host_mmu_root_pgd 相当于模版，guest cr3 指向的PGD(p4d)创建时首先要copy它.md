---
modified: 2026-09-18T09:17:00+08:00
---

首先，在vm init时，获取全局的 `host_mmu_root_pgd`:
```cpp
kvm_arch_init_vm
=> kvm_x86_call(vm_init) -- pvm_vm_init
   => kvm->arch.host_mmu_root_pgd = host_mmu_root_pgd
```

在guest访问某个地址触发page fault时,  首先会遍历guest pagetable创建影子页表，而如果 TOP shadow page table缺失，则会首先 将 `kvm->arch.host_mmu_root_pgd` 指向的页表作为模版 copy。这样Guest CR3的地址空间中，就拥有了`host kernel` 的地址映射，只不过这些地址映射是 `supervisor` 的访问权限:

首先`4-level page` 和 `5-level page` 为Guest kernel 预留的Hole 分布不同。
* 4-level page 在最高的页表 level 有一个hole(pgd)
* `5-level page` 有两个Hole，这两个Hole 在处在两个不同的 页表 level
	* PGD
	* `PGD[511] -> P4D`(`PGD[511]`指向的P4D)
所以，对于5-level page 来说，需要copy上面的两个页表

***
对于 4-level page 和 5-level page 都需要copy PGD， 具体流程：
```cpp
kvm_mmu_get_child_sp
=> kvm_mmu_get_shadow_page
   => __kvm_mmu_get_shadow_page
      => kvm_mmu_alloc_shadow_page
         # host_mmu_root_pgd 只有PVM的虚拟机会使用, 
         # role.level 表示本次操作的 shadow page table的层级,
         # 这个分支为真说明，PVM VM PGD的shadow page table 缺失
         => if kvm->arch.host_mmu_root_pgd && role.level == HOST_ROOT_LEVEL
            => memcpy(sp->spt, kvm->arch.host_mmu_root_pgd, PAGE_SIZE)
```

***
而对于5-level page 要额外处理 `PGD[511]->P4D`, 这个页表同样也需要copy下:
```cpp
kvm_mmu_get_child_sp
=> if pvm_mmu_p4d_at_la57_pgd511(vcpu->kvm, sptep))
     # 有两个条件，必须是pvm虚拟机+host使用了la57, 否则就不用copy
     => if !pgtable_l5_enable || !kvm->arch.host_mmu_root_pgd
        \-> return false
     # 本次要创建的影子是否是 `PGD[511]->P4D`
     => return sptep_to_sp(sptep)->role.level == 5 && spte_index(sptep) == 511
   \-> role.host_mmu_la57_top_p4d = 1
```