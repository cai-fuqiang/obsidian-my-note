---
创建时间: 2026-07-03 15:33:49
问题分类: kpatch/orc
问题缘由: 修复cve-2026-31431导致失败
---

# 问题现象

安装kpatch后, 使能热补丁出现下面报错:

```
[root@ak-mistack-10-100-4-43 15:31:17 wangfuqiang49]# echo 1 > /sys/kernel/livepatch/klp_mitigatecve202631431/enabled

bash: echo: write error: Invalid argument

[root@ak-mistack-10-100-4-43 15:31:39 wangfuqiang49]# dmesg |tail
[25133839.449753] livepatch: bash:2664516 has an unreliable stack, ret=-22
[root@ak-mistack-10-100-4-43 15:31:42 wangfuqiang49]#
```

# 问题调试

调试脚本: [[bpftace脚本_调试orc]]

## 客户环境

```
orc_find ret(ffffffffbb21da14) ip(ffffffffb956257f)        new_sync_write+271
unwind_next_frame ret(1)
unwind_get_return_address address(ffffffffb95653b7)
consume_entry :addr ffffffffb95653b7
consume_entry addr(ffffffffb95653b7) ret(1)
orc_find ret(ffffffffbb21e7f4) ip(ffffffffb95653b6)        vfs_write+438
unwind_next_frame ret(1)
unwind_get_return_address address(ffffffffb92695e0)
consume_entry :addr ffffffffb92695e0
consume_entry addr(ffffffffb92695e0) ret(1)
orc_find ret(ffffffffbb17df94) ip(ffffffffb92695df)
unwind_next_frame ret(0)
arch_stack_walk_reliable ret : -22
```

查看orc 返回的ip
```
0xffffffffb956257f <new_sync_write+271>: rorb (%rdi)
crash> dis ffffffffb95653b6
0xffffffffb95653b6 <vfs_write+438>: decl -0x77(%rcx)
crash> dis ffffffffb92695df
0xffffffffb92695df <elfcorehdr_read+63>: int3
crash> struct orc_entry ffffffffbb17df94
```

## 家里环境
我们来看下正常机器:

```
unwind_get_return_address address(ffffffffb9d62580)
consume_entry :addr ffffffffb9d62580
consume_entry addr(ffffffffb9d62580) ret(1)
orc_find ret(ffffffffbba1da14) ip(ffffffffb9d6257f)      new_sync_write+271
unwind_next_frame ret(1)
unwind_get_return_address address(ffffffffb9d653b7)
consume_entry :addr ffffffffb9d653b7
consume_entry addr(ffffffffb9d653b7) ret(1)
orc_find ret(ffffffffbba1e7f4) ip(ffffffffb9d653b6)      vfs_write+438
unwind_next_frame ret(1)
unwind_get_return_address address(ffffffffb9d6573f)    
consume_entry :addr ffffffffb9d6573f
consume_entry addr(ffffffffb9d6573f) ret(1)
orc_find ret(ffffffffbba1e944) ip(ffffffffb9d6573e)
unwind_next_frame ret(1)
unwind_get_return_address address(ffffffffba462d0d)
consume_entry :addr ffffffffba462d0d
consume_entry addr(ffffffffba462d0d) ret(1)
orc_find ret(ffffffffbbbb5f60) ip(ffffffffba462d0c)
unwind_next_frame ret(1)
unwind_get_return_address address(ffffffffba600099)
consume_entry :addr ffffffffba600099
consume_entry addr(ffffffffba600099) ret(1)
orc_find ret(ffffffffbbbb9f8c) ip(ffffffffba600098)
unwind_next_frame ret(1)
arch_stack_walk_reliable ret : 0
```

crash调试:
```
crash> dis ffffffffb9d6257f
0xffffffffb9d6257f <new_sync_write+271>:        rorb   (%rdi)
crash> dis ffffffffb9d653b6
0xffffffffb9d653b6 <vfs_write+438>:     decl   -0x77(%rcx)
crash> dis ffffffffb9d6573e
0xffffffffb9d6573e <ksys_write+94>:     decl   -0x77(%rcx)
crash> dis ffffffffba462d0c
0xffffffffba462d0c <do_syscall_64+60>:  rorb   (%rdi)
crash> dis ffffffffba600098
0xffffffffba600098 <entry_SYSCALL_64_after_hwframe+96>: decl   -0x75(%rax)
```

**可以发现家里环境==堆栈是正常的可以推导到 syscall 入口==**


## 对比分析

那两者的分叉口在, `new_sync_write->vfs_write->xxxx`, 根据orc的原理，也就是通过`vfs_write+438`这个IP，得到的`orc_entry`出了问题

我们先在家里(**正常环境**) 测试下ORC的流程。

计算offset:
```
crash> p _stext
_stext = $2 =
 {<text variable, no debug info>} 0xffffffffb9a00000
crash> p (0xffffffffb9d6257f-0xffffffffb9a00000)
$3 = 3548543
crash> p (0xffffffffb9d6257f-0xffffffffb9a00000)/(1<<8)
$4 = 13861
crash> p ((unsigned int *)&orc_lookup)[13861]
$9 = 126750
crash> p &(( struct orc_entry *)&__start_orc_unwind)[126750]
$14 = (struct orc_entry *) 0xffffffffbba1da14

crash> p ((int *)&__start_orc_unwind_ip)[126750]
$53 = -28185124
crash>  p &((int *)&__start_orc_unwind_ip)[126750]
$55 = (int *) 0xffffffffbb8436a8
crash> dis 0xffffffffbb8436a8-28185124
0xffffffffb9d62484 <new_sync_write+20>: mov    %gs:0x28,%rax

# 下一个元素
crash> p ((int *)&__start_orc_unwind_ip)[126751]
$54 = -28184827
crash> dis 0xffffffffbb8436ac-28184827
0xffffffffb9d625b1 <new_sync_write+321>:        pop    %rbx
```

目标ip为`ffffffffb9d6257f new_sync_write+271`, 其实也符合预期，因为在
```
0xffffffffb9d62484~0xffffffffb9d625b1
```
之间并未变更 sp.

查看其 `orc_entry`:
```
crash> struct orc_entry ffffffffbba1da14
struct orc_entry {
  sp_offset = 136,
  bp_offset = -16,
  sp_reg = 5,
  bp_reg = 1,
  type = 0,
  end = 0
}
```

new_sync_write:
```
0xffffffffb9d62470 <new_sync_write>:    nopl   0x0(%rax,%rax,1) [FTRACE NOP]
0xffffffffb9d62475 <new_sync_write+5>:  push   %rbp
0xffffffffb9d62476 <new_sync_write+6>:  mov    %rdx,%r8
0xffffffffb9d62479 <new_sync_write+9>:  mov    %rcx,%rbp
0xffffffffb9d6247c <new_sync_write+12>: push   %rbx
0xffffffffb9d6247d <new_sync_write+13>: mov    %rdi,%rbx
0xffffffffb9d62480 <new_sync_write+16>: sub    $0x70,%rsp
0xffffffffb9d62484 <new_sync_write+20>: mov    %gs:0x28,%rax
```

一共占用了`8(ip)+8(rbp)+8(rbx)+0x70(sub $0x70,%rsp) = 0x88 = 136`

# 客户环境

