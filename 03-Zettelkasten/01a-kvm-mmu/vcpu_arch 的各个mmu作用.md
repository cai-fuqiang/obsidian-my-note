---
type: permanent
status: seed
category: kvm_mmu
summary:
sources: []
created: 2026-09-10T18:04:36+08:00
modified: 2026-09-10T18:46:43+08:00
QA:
---
# summary

> [!summary]
> `= this.summary`

# details

* `*mmu`: 发生`pagefault/ept volation` 时使用的mmu。
* `root_mmu`:  用于运行L1/non-nested vm
* `guest_mmu`: 运行L2所使用的mmu, 用来影子L1 EPT(仅用于嵌套虚拟化)
* `nested_mmu`: 用于walk L2 page tables. 其仅用于page table walking，不用于fault。因为`nested_mmu`的出发点是`VA`, 而当运行`L2` 时，L2 的PF不会trap到L0.一般用于指令模拟。
* `walk_mmu`: 用于`gva_to_pga` 的转换
# 依据

# relate

# TODO
* [ ] [[补充依据]]