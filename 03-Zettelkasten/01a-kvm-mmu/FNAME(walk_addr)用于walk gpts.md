---
type: literature
status: reading
category:
summary: "作用: FNAME(walk_addr) 用于walk gpts, 得到整条gpt链的关键信息（各个gpte指向的gfn以及access），如果walk 中断，例如not present 触发的`#PF` 也通过该函数进行报告"
created: 2026-09-15T21:45:13+08:00
modified: 2026-09-15T22:55:41+08:00
QA:
---

# summary

> [!summary]
> `= this.summary`

# 引用

## 函数参数

| 参数类型   | 参数作用                        |
| ------ | --------------------------- |
| walker | 出参得到page table walk的结果      |
| vcpu   |                             |
| mmu    |                             |
| addr   | GVA 或者 L2 GPA (也可能是 L2 GVA) |
| access | 本次访问的access right           |

## 调用关系

`FNAME(walk_addr_generic)`

## 其他思考

`walk_addr_generic()` 模拟的是hardware mmu的遍历过程。我们来比较下两者:

|              | hardware mmu               | nest mmu                                                       |
| ------------ | -------------------------- | -------------------------------------------------------------- |
| 存储结果         | final gfn, 综合的access write | all level page table entry {gfn, access write}, to create spte |
| 如果遍历中断是否产生PF | 是                          | 是                                                              |

所以最大的不同是，nest mmu 最终是要存储所有级别的pte 和access right，而不是只获取 final. 因为要靠这些信息构造各个级别的影子页表。[[构造影子页表为什么需要原页表的gfn信息]]


## 代码流程详细解释
```sh
FNAME(walk_addr_generic)
=> walk->max_level = walk->level = mmu->cpu_role.base.level;
=> pte = kvm_mmu_get_guest_pgd(vcpu, mmu);
   => mmu->get_guest_pgd(vcpu); ## nested_ept_get_eptp
      => get_vmcs12(vcpu)->ept_pointer;
## 这里++的目的是，表示改pte是比PGD还还高一层(CR3, EPTP)
=> ++walker->level
=> do while(!FNAME(is_last_gpte(mmu, walker->level, pte)))
   => --walker->level;
   # 根据addr 和当前level获取在GPT中的 pte index
   => index = PT_INDEX(addr, walker->level);
   # 根据pte_prev val 获取 gfn
   => table_gfn = gpte_to_gfn(pte);
   # pte 在GPT中的offset(byte单位)
   => offset    = index * sizeof(pt_element_t);
   # pte具体的 gpa
   => pte_gpa   = gfn_to_gpa(table_gfn) + offset;
   # 赋值walker 中的 table_gfn 和 pte_gpa
   => walker->table_gfn[walker->level - 1] = table_gfn;
   => walker->pte_gpa[walker->level - 1] = pte_gpa;
   # 获取 real_gpa, 何为 REAL!!
   ## 主要是针对嵌套虚拟化中addr 为GVA的, 类似于指令模拟操作数 为 gva(l2)
   ##
   ## 在这种场景下，在做Guest Page Table Walk 是，我们通过遍历L2 Page Table, 获取
   ## 到的是, L2 GPA, 而在 Guest Page Table walk 时，需要访问页表内容。而L0访问只
   ## 能访问HVA, 而HVA 最终需要L1 GPA 转换得到(需要借助 L1 GPA 找到 qemu va 继而找
   ## 到 HPA), 所以需要进行L2 GPA->L1 GPA的translate, 那就需要遍历 L1 EPT
   => real_gpa = kvm_translate_gpa(vcpu, mmu, gfn_to_gpa(table_gfn),
        nested_access, &walker->fault);
      # nested_mmu 表示要翻译L2 GVA->GPA, 常用作指令模拟
      => if (mmu != &vcpu->arch.nested_mmu) return gpa
      => translate_nested_gpa()
         # 这里比较关键哈，相当于gva_to_gpa使用的翻译页表是L1 mmu, 也就是L1 为
         # l2 准备的 ept
         => mmu = vcpu->arch.mmu
         # /* NPT walks are always user-walks */
         # 不知道何作用, 什么叫user walk
         => access |= PFERR_USER_MASK;
         => t_gpa = mmu->gva_to_gpa(vcpu, mmu, gpa, access, exception)
   ## 获取到具体的slot
   => slot = kvm_vcpu_gfn_to_memslot(vcpu, gpa_to_gfn(real_gpa));
   # 获取到 real_gpa 对应的hva 但是hva 是page frame align
   => host_addr = gfn_to_hva_memslot_prot(slot, gpa_to_gfn(real_gpa),
				&walker->pte_writable[walker->level - 1]);
   # 获取 ptep 的 hva
   => ptep_user = (pt_element_t __user *)((void *)host_addr + offset);
   # kvm只负责GPA->HPA映射。如果GPT本身是not present, 说明GVA->GPA映射没有建立全。
   # 则需要报告异常给 guest
   => if (unlikely(!FNAME(is_present_gpte)(pte))) 
      \> goto error;
   => walker->ptes[walker->level - 1] = pte;
=> 忽略很多代码
=> 
```
# related
1. [[kvm-mmu-page-walker 用于存储gpt walk中的关键信息|page]]
## 可提炼的永久笔记
- [ ]
## 其他引用笔记

# TODO
* kvm_vcpu_gfn_to_memslot
* gfn_to_hva_memslot_prot