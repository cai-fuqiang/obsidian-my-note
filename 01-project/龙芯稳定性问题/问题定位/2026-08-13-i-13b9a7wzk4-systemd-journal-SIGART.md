---
data: 2026-08-13
问题分类: guest app SIGART
是否定位成功: false
目前结论: 用户态访问某个地址触发异常(SIGART), 但是该地址有虚拟地址段映射，并且是8字节对齐。不应该产生异常
is_issue: true
instance: i-13b9a7wzk4
share_link: https://share.note.sx/lt4ou63y#qRvtx3zJMVzsqF6GkeO/5Q
share_updated: 2026-08-20T16:20:50+08:00
---
# 问题现象
kernel dmesg有报错 -- `systemd-journal` 触发了 `SIGART`, 并产生coredump
```
[46098.293237] systemd-coredump[57246]: elfutils disabled, parsing ELF objects not supported
[46098.295349] systemd-coredump[57246]: Process 585 (systemd-journal) of user 0 dumped core.
[46098.296239] systemd-coredump[57246]: Coredump diverted to /var/lib/systemd/coredump/core.systemd-journal.0.b52f811bcbb9454ca53a81314ae41ea9.585.1786590723000000.lz4
```

# 初步分析

通过gdb 调试coredump，查看堆栈:
```
(gdb) bt
#0  0x00007ffff0f18ec8 in journal_file_append_object (f=f@entry=0x55555d1f2f70, type=type@entry=OBJECT_ENTRY, size=148, ret_object=ret_object@entry=0x7ffffbe0ef08, ret_offset=ret_offset@entry=0x7ffffbe0ef10)
    at ../src/libsystemd/sd-journal/journal-file.c:1257
#1  0x00007ffff0f19858 in journal_file_append_entry_internal (f=f@entry=0x55555d1f2f70, ts=0x7ffffbe0f400, boot_id=0x7ffffbe0f198, machine_id=<optimized out>, xor_hash=14388535897953133960,
    items=0x7ffffbe0efb0, n_items=n_items@entry=21, seqnum=0x7ffff1068010, seqnum_id=0x7ffff1068000, ret_object=0x0, ret_offset=0x0) at ../src/libsystemd/sd-journal/journal-file.c:2363
#2  0x00007ffff0f1b59c in journal_file_append_entry (f=f@entry=0x55555d1f2f70, ts=<optimized out>, ts@entry=0x7ffffbe0f400, boot_id=<optimized out>, boot_id@entry=0x0, iovec=iovec@entry=0x7ffffbe0f530,
    n_iovec=n_iovec@entry=21, seqnum=<optimized out>, seqnum_id=<optimized out>, ret_object=ret_object@entry=0x0, ret_offset=<optimized out>) at ../src/libsystemd/sd-journal/journal-file.c:2614
#3  0x0000555556c2b904 in server_write_to_journal (priority=46, n=21, iovec=0x7ffffbe0f530, uid=<optimized out>, s=0x7ffffbe11ea0) at ../src/journal/journald-server.c:952
#4  server_dispatch_message_real (s=0x7ffffbe11ea0, iovec=0x7ffffbe0f530, n=<optimized out>, m=<optimized out>, c=<optimized out>, tv=<optimized out>, priority=<optimized out>, object_pid=<optimized out>)
    at ../src/journal/journald-server.c:1155
```

给一个, 数据结构赋值
```
(gdb) l 1257
1252	
1253	        r = journal_file_move_to(f, type, false, p, size, (void**) &o);
1254	        if (r < 0)
1255	                return r;
1256	
1257	        o->object = (ObjectHeader) {
1258	                .type = type,
1259	                .size = htole64(size),
1260	        };
```

数据结构的地址为: 
```
(gdb) p o
$2 = (Object *) 0x7fffef5bba38
```

出错汇编为:
```
   0x00007ffff0f18ec4 <+492>:	ld.d        	$t0, $sp, 8
=> 0x00007ffff0f18ec8 <+496>:	stptr.d     	$zero, $t0, 0
   0x00007ffff0f18ecc <+500>:	st.b        	$s2, $t0, 0
```
大概作用是: 将 `$zero` 存放到 `$t0 + 0`地址处

`$t0`寄存器为 `r12`:
```
r12            0x7fffef5bba38      140737209154104
```

该地址为 `o`变量的地址，并且该地址有映射:
```
(gdb) x/1xg 0x7fffef5bba38
0x7fffef5bba38:	0x000658e70517124f

(gdb) i proc m 
      0x7fffef1c4000     0x7fffef9c4000   0x800000        0x0 /var/log/journal/system.journal
```

# 暂时结论

> [!bug] 用户态访问`0x7fffef5bba38`地址触发异常(`SIGART`), 但是该地址有虚拟地址段映射，并且是8字节对齐。不应该产生异常