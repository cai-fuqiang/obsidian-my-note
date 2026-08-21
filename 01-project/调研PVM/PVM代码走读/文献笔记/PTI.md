# `sp0` 赋值
```sh
cpu_init
# cpu_entry_stack() 返回 entry_stack 数据结构
=> load_sp0((unsigned long)(cpu_entry_stack(cpu) + 1))

cpu_entry_stack
=> return &get_cpu_entry_area(cpu)->entry_stack_page.stack;
   => va = CPU_ENTRY_AREA_PER_CPU + cea_offset(cpu) * CPU_ENTRY_AREA_SIZE;
   => return va
```

> [!summary] `sp0`加载为该cpu 分配的栈顶 (`cpu_entry_stack(cpu) + 1`中的 `+1`表示从栈底计算到栈顶)
# cea_offset初始化

```sh
init_cea_offsets
# 如果不使能kaslr的话，顺序赋值_cea_offset
=> if (!kaslr_enable())
   => for_each_possible_cpu(i)
      => per_cpu(_cea_offset, i) = i
   => return
# 这里为啥要减去一个PAGE_SIZE， TODO
=> max_cea = (CPU_ENTRY_AREA_MAP_SIZE - PAGE_SIZE) / CPU_ENTRY_AREA_SIZE;
=> for_each_possible_cpu(i)
   => cea = get_random_u32_below(max_cea);
   => for_each_possible_cpu(j)
      => if (cea_offset(j) == cea)
         => goto again
      # i == j，说明已经遍历完当前数组中所有有效成员
      => if (i == j)
         => break
    => per_cpu(_cea_offset, i)
```

> [!summary] 在未开启`kaslr`时，每个cpu的`cea_offset`按照该cpu的`cpu_index`顺序赋值。在使能了`kaslr`后，该offset 则随机赋值。（但是赋的值在 `CPU_ENTRY_AREA_MAP_SIZE`所代表区域的范围内)