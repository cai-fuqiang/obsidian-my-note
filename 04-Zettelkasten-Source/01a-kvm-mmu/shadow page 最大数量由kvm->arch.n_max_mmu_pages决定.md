---
type: literature
status: reading
category: kvm_mmu
summary: 该值用来限制当前虚拟机所申请的最大mmu pages的数量，其可以通过qemu kvm-shadow-mem prop设置，如果未设置默认为当前内存总量的 $\frac{1}{50}$
created: 2026-09-10T14:00:39+08:00
modified: 2026-09-10T18:51:55+08:00
QA:
  - shadow page 生命周期?
  - shadow page 有没有最大数量限制
share_link: https://share.note.sx/64eylvaq#L66BftnQDdBqkFMnbOpwQw
share_updated: 2026-09-10T15:08:33+08:00
---
# summary

> [!summary]
> `= this.summary`

# 引用
`kvm_mmu_available_pages()` 用来获取当前可获取的 `mmu pages`数量:

### 使用n_max_mmu_pages做判断的调用栈

```cpp
direct_page_fault/FNAME(page_fault)/mmu_alloc_direct_roots/mmu_alloc_shadow_roots
=> make_mmu_pages_available
   => avail = kvm_mmu_available_pages
   => if avail > KVM_MIN_FREE_MMU_PAGES(5)
      \-> return 0
   => kvm_mmu_zap_oldest_mmu_pages(vcpu->kvm, KVM_REFILL_PAGES - avail);
   => if (!kvm_mmu_available_pages(vcpu->kvm))
      \-> return -ENOSPC

```

当发现avail page较少时，回先 **==直接==回收** mmu pages, 如果回收不到，就直接返回失败(`ENOSPC`)

`kvm_mmu_avail_pages` 实现

```cpp
static inline unsigned long kvm_mmu_available_pages(struct kvm *kvm)
{
    //n_max_mmu_pages:  本虚拟机支持的最大mmu pages 数量
    //mmu_shadow_pages: 本虚拟机已经申请的mmu pages 数量
	if (kvm->arch.n_max_mmu_pages > kvm->stat.mmu_shadow_pages)
		return kvm->arch.n_max_mmu_pages -
			kvm->stat.mmu_shadow_pages;
	return 0;
}
```

### 初始化流程

`kvm_mmu_change_mmu_pages()` 用于初始化 `n_max_mmu_pages` 变量:

```cpp
kvm_mmu_change_mmu_pages(kvm, goal_nr_mmu_pages)
=> LOCK(kvm->mmu_lock)
=> if kvm->stat.mmu_shadow_pages > goal_nr_mmu_pages
   # 如果新设置的值比当前小，则使用 "尽量" 将 mmu_shadow pages 回收到 
   # goal_nr_mmu_pages值
   \-> kvm_mmu_zap_oldest_mmu_pages(kvm, kvm->stat.mmu_shadow_pages -
	    goal_nr_mmu_pages)
   \-> goal_nr_mmu_pages = kvm->stat.mmu_shadow_pages;
=> goal_nr_mmu_pages = kvm->stat.mmu_shadow_pages;
```

而调用`kvm_mmu_change_mmu_pages` 有两个路径:
* vm_ioctl(`KVM_SET_NR_MMU_PAGES`)
```cpp
# kernel path
kvm_vm_ioctl_set_nr_mmu_pages
=> kvm_mmu_change_mmu_pages
# 设置n_requested_mmu_pages表示用户态侧请求设置的 mmu_pages数量
# 所以 即便是在用户态主动调用ioctl设置max mmu pages,
# n_request_mmu_pages 并不一定和 n_max_mmu_pages 相同，毕竟从上面的代码片段看，
# 其是尽力回收(可能回收不到)
=> kvm->arch.n_requested_mmu_pages = kvm_nr_mmu_pages;


# qemu path
kvm_vm_set_nr_mmu_pages
=> shadow_mem = object_property_get_int(,"kvm-shadow-mem",)
=> if (shadow_mem != -1)
   => shadow_mem /= 4096;
   => ret = kvm_vm_ioctl(s, KVM_SET_NR_MMU_PAGES, shadow_mem);
```
可见，用户态 QEMU 可以通过 `kvm-shadow-mem` 自定义`kvm-shadow-mem` 最大值，从而控制VMM因shadow page 而申请的内存总量。
* vm init
如果QEMU没有主动设置，则会根据当前memslots 所容纳的内存总量，根据一个衰减因子，计算一个值，具体代码:
```cpp
kvm_arch_commit_memory_region
//===(1)===
=> if (!kvm->arch.n_requested_mmu_pages && 
	(change == KVM_MR_CREATE || change == KVM_MR_DELETE))
   //==(2)==
   => nr_mmu_pages = kvm->nr_memslot_pages / KVM_MEMSLOT_PAGES_TO_MMU_PAGES_RATIO; //(50)
   => nr_mmu_pages = max(nr_mmu_pages, KVM_MIN_ALLOC_MMU_PAGES); //(64)
   => kvm_mmu_change_mmu_pages(kvm, nr_mmu_pages);
```
1. 首先，如果用户态设置了，那就使用固定的值，其次，只有当memslot有增减时，才会重新计算。
2. 会根据当前memslot表示的最大页的数量的 $\frac{1}{50}$ 作为最大的mmu pages的数量，另外mmu_pages数量有一个最小值 -- $64$
> [!example] 我们来使用crash 调试验证下
> ```
> crash> struct kvm ffffa4b74bcce000 |grep -E 'n_max_mmu_pages|requested|nr_memslot_pages'
>  nr_memslot_pages = 41945090,
>    n_requested_mmu_pages = 0,
>    n_max_mmu_pages = 838901,
> crash> p 41945090/50
>   $4 = 838901
> ```

## 可提炼的永久笔记
- [ ]
## 其他引用笔记
* [[kvm_stat-mmu_shadow_pages表示当前已经分配的 shadow_pages数量 | mmu_shadow_pages作用]]
# TODO
* [x] `mmu_shadow_pages` && `n_used_mmu_pages` 这两者的区别 ✅ 2026-09-10
	* 看叉劈了, 这是两个内核版本的代码，`mmu_shadow_pages == n_used_mmu_pages`. 上面笔记已经修改