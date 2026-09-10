---
created: 2026-09-10T20:36:12+08:00
modified: 2026-09-10T20:36:12+08:00
---
```
mmu_zap_unsync_children
=> while (mmu_unsync_walk(parent, &pages))
   
```

```
mmu_unsync_walk
```



# mmu_pages_add
```cpp
static int mmu_pages_add(struct kvm_mmu_pages *pvec, struct kvm_mmu_page *sp,
			 int idx)
{
	int i;
	//sp->unsync后，其会查找pvec原数组中的sp，看看是否有一样的 如果有直接返回
	if (sp->unsync)
		for (i=0; i < pvec->nr; i++)
			if (pvec->page[i].sp == sp)
				return 0;
	//但是如果sp->sync == false, 直接加入到数组最后
	pvec->page[pvec->nr].sp = sp;
	pvec->page[pvec->nr].idx = idx;
	pvec->nr++;
	return (pvec->nr == KVM_PAGE_ARRAY_NR);
}
```