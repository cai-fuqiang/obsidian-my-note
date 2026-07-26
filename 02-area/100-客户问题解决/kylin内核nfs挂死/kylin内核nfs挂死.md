# 问题现象

```ad-error
collapse: closea

[ 1928.886924] CPU: 84 PID: 52027 Comm: umount.nfs Kdump: loaded Tainted: G           OE     4.19.90-23.57.v2101.ky10.x86_64 #1
[ 1928.899930] Hardware name: Suma R6240H0/62DB32, BIOS CXYH051029 09/06/2023
[ 1928.908096] RIP: 0010:kfree+0x4f/0x160
[ 1928.912764] Code: 80 49 01 da 0f 82 1b 01 00 00 48 c7 c7 00 00 00 80 48 2b 3d 3b b6 0b 01 49 01 fa 49 c1 ea 0c 49 c1 e2 06 4c 03 15 19 b6 0b 01 <49> 8b 42 08 48 8d 50 ff a8 01 4c 0f 45 d2 49 8b 52 08 48 8d 42 ff
[ 1928.934206] RSP: 0018:ffffb2bc8f2af678 EFLAGS: 00010203
[ 1928.940523] RAX: 00000000000001fe RBX: 9d819651fb8d1bfd RCX: 0000000000000000
[ 1928.948973] RDX: 0000000000000000 RSI: ffffd4520002fdc0 RDI: 0000693200000000
[ 1928.957422] RBP: ffff96fd80bf7000 R08: 0000000000000000 R09: 0000000000000000
[ 1928.965871] R10: 0275dc4f51ee3440 R11: 0000000000000000 R12: ffffffffc0ae363d
[ 1928.974321] R13: 0000000000000000 R14: ffff96fd6181ec58 R15: 0000000000000001
[ 1928.982769] FS:  00007fe8baa22840(0000) GS:ffff96fdbfd00000(0000) knlGS:0000000000000000
[ 1928.992284] CS:  0010 DS: 0000 ES: 0000 CR0: 0000000080050033
[ 1928.999182] CR2: 00007fc0bd5f8768 CR3: 000000103c93e000 CR4: 00000000003406e0
[ 1929.007631] Call Trace:
[ 1929.010857]  nfs_readdir_clear_array+0x4d/0x70 [nfs]
[ 1929.016887]  page_cache_free_page.isra.35+0x1a/0x90
[ 1929.022817]  delete_from_page_cache_batch+0x1cf/0x2c0
[ 1929.028946]  truncate_inode_pages_range+0x24d/0x910
...
[ 1929.368622]  nfs_evict_inode+0x15/0x30 [nfs]
[ 1929.373876]  evict+0x115/0x2b0
...
[ 1929.382721]  dispose_list+0x48/0x60
[ 1929.387099]  evict_inodes+0x16c/0x1b0
[ 1929.391674]  generic_shutdown_super+0x3f/0x120
[ 1929.397123]  nfs_kill_super+0x1b/0x40 [nfs]
[ 1929.402275]  deactivate_locked_super+0x3f/0x70
[ 1929.407718]  cleanup_mnt+0x3b/0x80
[ 1929.412001]  task_work_run+0x8a/0xb0
[ 1929.416482]  exit_to_usermode_loop+0xeb/0xf0
[ 1929.421733]  do_syscall_64+0x1a3/0x1c0
[ 1929.426402]  entry_SYSCALL_64_after_hwframe+0x44/0xa9
[ 1929.432528] RIP: 0033:0x7fe8bb0cad1b
```

发生在内核在umount时，会kill super ，evict inodes, release pagecache. nfs的dir pagecache比较特殊，其不只是block 块的映射，还有一些其他的数据，这些其他的数据里面存放了一些指向kernel memory的指针。

具体指令如下
```
80 49 01 da          orb    $0xda, 0x1(%r9)
0f 82 1b 01 00 00    jc     0x121                  ; 如果进位则跳转
48 c7 c7 00 00 00 80 mov    $0xffffffff80000000, %rdi
48 2b 3d 3b b6 0b 01 sub    0x10bb63b(%rip), %rdi  ; 减去一个内存变量值
49 01 fa             add    %rdi, %r10
49 c1 ea 0c          shr    $0xc, %r10             ; 右移 12 位（常用于获取页帧号 PFN）
49 c1 e2 06          shl    $0x6, %r10             ; 左移 6 位（相当于乘以 64，即 sizeof(struct page)）
4c 03 15 19 b6 0b 01 add    0x10bb619(%rip), %r12  ; 加上 vmemmap 的基地址

; ------- 以下是 <49> 开始的部分 -------
49 8b 42 08          mov    0x8(%r10), %rax        ; 将 R10+8 地址处的值存入 RAX
48 8d 50 ff          lea    -0x1(%rax), %rdx       ; RDX = RAX - 1
a8 01                test   $0x1, %al              ; 测试 AL 最低位是否为 1
4c 0f 45 d2          cmovne %rdx, %r10             ; 如果不为0（条件满足），将 RDX 赋值给 R10
49 8b 52 08          mov    0x8(%r10), %rdx        ; 将 R10+8 地址处的值存入 RDX
48 8d 42 ff          lea    -0x1(%rdx), %rax       ; RAX = RDX - 1
```


# 代码分析

## readdir流程
```
nfs_readdir
  readdir_search_pagecache
    find_and_lock_cache_page
      nfs_readdir_xdr_to_array
        nfs_readdir_alloc_pages
        nfs_readdir_xdr_filler
        nfs_readdir_folio_filler
          do
           nfs_readdir_folio_array_append
           nfs_readdir_folio_array_alloc/nfs_readdir_folio_get_next 
           nfs_readdir_folio_array_append
             name = nfs_readdir_copy_name
             array->size++;
             cache_entry = array->array[array->size - 1]
             //赋值cachename
             cache_entry->name = name
          while()
```



## nfs_readdir_clear_array

```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/linux/v7.1-rc3/fs/nfs/dir.c"
LINES: "220-230"
TITLE: "nfs_readdir_clear_array"
FONT_SIZE: 12
COMMENTS:
  225: |-
    拿到folio所在page的虚拟地址
  226: |-
    `nfs_cache_array`中存放的是一个关于目录数组，其中 `nfs_cache_array.array[].name`是经过动态
    申请的字符串
```

## nfs_readdir_folio_filler

filler的意思是填充pagecache
## vfs_symlink
```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/linux/v7.1-rc3/fs/nfs/dir.c"
LINES: "2631-2685"
TITLE: ""
FONT_SIZE: 12
COMMENTS:
  2649: 分配页
  2654: 将path copy到刚刚分配的page中
  2659: |-
    将数据copy到后段
    ```ad-todo
    需要注意的是，在->symlink()调用之前, 并没有分配该文件的的inode.
    ```
  2676: 将folio添加到 i_mapping中
  2678: 如果成功标记为 uptodate
```


## nfs3_proc_symlink

```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/linux/v7.1-rc3/fs/nfs/nfs3proc.c"
LINES: "552-586"
TITLE: "nfs3_proc_symlink"
FONT_SIZE: 12
COMMENTS:
  565: |-
    create nfs3_createdata
    ```ad-todo
    走读nfs3_createdata代码
    ```
  568: |-
    赋值msg.rpc_proc为 `NFS3PROC_SYMLINK`，然后赋值相关symlink成员
  576: 同步到远端
  572: 释放createdata
```
# nfs3_createdata

```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/linux/v7.1-rc3/fs/nfs/nfs3proc.c"
LINES: "299-314"
TITLE: "nfs_createdata"
FONT_SIZE: 12
COMMENTS: 
  306: |-
    ```ad-important
    注意这里的rcp_argp和rpc_resp的赋值。说明data->res中在rpc得到了填充
    ```
```
# nfs3_do_create

```
nfs3_do_create
// 在这一步已经赋值了 data->res [[kylin内核nfs挂死#nfs3_createdata |nfs3_createdata]]
=> rpm_call_sync(,&data->msg)
=> nfs_add_or_obtain
   => nfs_fhget
      => if (inode_state_read_one(inode) & I_NEW)
         ## fattr为 data->res.fattr
         => inode->i_mode = fattr->mode
         => if (S_ISDIR(inode->i_mode)) 
            ## 问题原因在这里，会根据服务端返回的
            => inode->i_fop = &nfs_dir_operations
```

# 总结

根据kylin调研结果 `NFS3PROC_SYMLINK` RPC  所得到的data.res.i_mode 得到的是DIR从而让inode->i_fop 赋值为`nfs_dir_operations`, 而软连接的pagecache中存放的是字符串，在后续的 `nfs_readdir_clear_array`中却当成了 `nfs_cache_array`处理。