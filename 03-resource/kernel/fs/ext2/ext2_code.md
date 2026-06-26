## ext2_get_blocks

<!-- LINES: "603-775"-->
## ext2_get_blocks - 注释部分

```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/runninglinuxkernel_5.0/rlk_5.0/fs/ext2/inode.c"
LINES: "603-621"
TITLE: "ext2_get_block"
FONT_SIZE: 12
COMMENTS:
  611: |-
    这个策略相当简单, 当新分配一个block时，我们应该确保整个链被分配后，才attach到最后的tree, 
    如果attach失败了, 则释放掉重新分配
  614: 这样做的最大好处是好做恢复，我们只需要release blocks 不会修改inode的任何内容
  621: |-
    单词翻译:
    * stratey - 相当
```

## ext2_get_blocks -- code part1

```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/runninglinuxkernel_5.0/rlk_5.0/fs/ext2/inode.c"
LINES: "621-644"
TITLE: "ext2_get_blocks - part1"
FONT_SIZE: 12
COMMENTS: 
  621:
  640: |-
    [[ext2 code#ext2_block_to_path -- code]]
```

## ext2_get_blocks -- code part2

```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/runninglinuxkernel_5.0/rlk_5.0/fs/ext2/inode.c"
LINES: "621-625, 645-679"
TITLE: "ext2_get_block -- code part2"
FONT_SIZE: 12
COMMENTS:
  645: |-
    [[ext2 code#ext2_get_branch - code]]
    partial 表示未建立映射的间接块的`Indirect`
    这里是在没加任何**锁**得情况下，来获取有第一个块所在的整个间接块的链，有哪些层
    已经创建了链接
  646: |-
    !partial 的意思是，所有的间接块都建立了映射。我们只需要干啥呢?
    验证下目前 **所要创建的数据块** 所在的 **已经建立映射的间接块链** 是否发生更改,
    （通过`verify_chain()`)
  648:
    获取第一个index所在的block
  651: |-
    这里我们要找出我们要操作的block的范围，除了`maxblocks`用户输入的参数外，还应该
    判断`blocks_to_boundary`, 该参数表示我们要操作整个tree 的一个block entry.
    
    例如，我们便利遍历 indirect block link时，发现
    ```
    third block entry
    -- second block entry a (want to fill(none now))
    -- second block entry b (next (none now))
    ```
    那么此时，我们本次操作该tree的最大的范围就是填充 **second block entry a** ，
    绝对不能触碰 `second block entry b`。 
    ```ad-todo
    title: 待解释
    因为恢复起来比较简单
    ```
    [[ext2_code#ext2_get_blocks - 注释部分]]
    [[ext2_code#ext2_block_to_path -- code]]
  654: |-
    chain数组中包含的`[entry, entry value(*entry)]`是否改变，如果改变了，有下面几种可能
    * ==A->NONE: 可能有别的cpu在做truncate (大概率)==
    * A->B: truncate后，有别分配了别的块（概率较低)
  660: |-
    如果被truncate了，那简单，我们在重新读一次。在重新构建`chain[]`
  663: |-
    这里partial的意思有所改变，其表示要重新构建的`chain[]`的最后一个数组, 在后面流程中，
    会从partial向前遍历数组，依次释放`chain[]->bh`(`brelse()`)
  666: |-
    **验证分配的block块是否是连续的! 如果不连续直接break, ==也就是说ext2_get_block
    只处理连续block==**
```

## ext2_get_blocks -- code part3

```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/runninglinuxkernel_5.0/rlk_5.0/fs/ext2/inode.c"
LINES: "621-625, 680-706"
TITLE: "ext2_get_block -- code part2"
FONT_SIZE: 12
COMMENTS:
  693: |-
    上面是在不加锁的情况下, 可能在该过程中，映射关系又发生了改变，所以下面在锁
    inode后，在做一次check
    
    另外，如果:
    * `err ==  -EAGAIN`: 在前面已经检测到chain发生改变。
    * `!verity_chain()`: 加锁后，发现`chain[]`发生改变

    这两种情况都属于在第一次read chain[]后，chain[]发生了改变,需要`rebuild chain[]`
  698: rebuild chain[]
  699: |-
    ```ad-todo
    title: 待继续思考(不理解)
    为什么这里没有再做循环,只是获取了当前index 的block index就返回了
    ```
  704: |-
    **那怎么能保证在这个过程中映射关系一直不变了呢? ==一直加锁一直爽(安全), 即便是走到got 
    it，ext2_get_blocks()返回，也是带着inode的锁==**
```

##  ext2_get_blocks -- code part4

```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/runninglinuxkernel_5.0/rlk_5.0/fs/ext2/inode.c"
LINES: "621-625,708-734"
TITLE: "ext2_get_blocks"
FONT_SIZE: 12
COMMENTS:
  712: |-
    ```ad-todo
    暂不关注
    ```
  715: |-
    找一个 "理想的" 分配该index block位置，有一些启发式算法，注意，这里只是找一个
    **理想的，但是并没有实际分配物理块，也没有判断该物理块是否已经被分配**
  717: |-
    要分配的indirect block数量.
    ```ad-note
    partial表示该indirect block 中关于该block index 所在的entry还未被填充。
    所以应该是==partial下一级level的indirect block未分配(`partial++`)==,
    所以这里要
    
    indirect_blks = (chain + depth) - partial ==- 1==
    ```
  719: |-
    [[ext2_code#ext2_blks_to_allocate -- code]]
    确认要分配 block 数量
  728: |-
    分配物理块，将分配的 ==可能不连续== 的物理块index 填充到 `new_blocks[]`
    [[ext2_code#ext2_alloc_blocks -- code]]
```

## ext2_get_block -- code part5

```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/runninglinuxkernel_5.0/rlk_5.0/fs/ext2/inode.c"
LINES: "621-625,736,756-775"
TITLE: ""
FONT_SIZE: 12
COMMENTS:
  736: |-
    ```ad-ignore
    忽略DAX部分
    ```
  759: 将更新的这些数据块们(实际上算上indirect block是一个tree) 更新到inode (将tree链接到一个entry上)
```

# ext2_block_to_path
## ext2_block_to_path 注释部分

```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/runninglinuxkernel_5.0/rlk_5.0/fs/ext2/inode.c"
LINES: "153-161"
TITLE: "ext2_block_to_path"
FONT_SIZE: 12
COMMENTS:
```

## ext2_block_to_path -- code

```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/runninglinuxkernel_5.0/rlk_5.0/fs/ext2/inode.c"
LINES: "163-203"
TITLE: "ext2_block_to_path"
FONT_SIZE: 12
COMMENTS:
   163: |-
     [[ext2 code#ext2_get_blocks -- code part1|caller]]
   166: 每个间接块所包含的 "指针"的数量(每个"指针"u32单位大小)
   167: 每个间接块所包含的 "指针"数量，并以2为底
   168: inode中的直接块的数量(一共15个数据块指针，12个为直接快，3个为间接块)
   169: 第一层间接块所能容纳的块数量
   170: 第二层间接块所能容纳的块数量
   174: |-
     `offset[]`用来存储申请该`i_block` index的块，所需要在各个层级的索引块中的offset，
     包括直接块各个间接块
   200: |-
     当boundary为空表示是否用了间接块, 我们分解下
     * `i_block & (ptrs - 1)` 表示在最后一级 的中 index
     * `final` 表示 最后一级中所能容纳的块的数量
     * `final - 1`表示最后一级中的容纳块的最大 index
     ==所以综合可得, `boundary`表示当前块所在的层级depth，到达下一级depth的距离,
     举个例子，当前块index(510) depth(2), depth(2)的第一个index为(511)，这时，
     `boundary = 511 - 510 = 1`==
     
     详细解释见 ==1.==
```

1. boundary解释
   ![[03-resource/kernel/fs/ext2/ext2_code.excalidraw.md#^group=HMcjdBRF|boundary|600]]

# ext2_get_branch

##  ext2_get_branch - 注释部分

```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/runninglinuxkernel_5.0/rlk_5.0/fs/ext2/inode.c"
LINES: "205-233"
TITLE: "ext2_get_branch"
FONT_SIZE: 12
COMMENTS:
```

## ext2_get_branch - code
```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/runninglinuxkernel_5.0/rlk_5.0/fs/ext2/inode.c"
LINES: "234-272"
TITLE: "ext2_get_branch - code"
FONT_SIZE: 12
COMMENTS:
  234: |-
    [[ext2 code#ext2_get_blocks -- code part2]]
    返回值表示 是否所有的间接块都被分配
  246: |-
    add_chain 代码展开
    ```embed-cpp
    PATH: "https://raw.githubusercontent.com/cai-fuqiang/runninglinuxkernel_5.0/rlk_5.0/fs/ext2/inode.c"
    LINES: "120-124"
    TITLE: "add_chain"
    FONT_SIZE: 12
    COMMENTS:
    120: |-
      * 关联bh
      * 保存entry 地址和值.
    ```
```

#  ext2_find_goal

```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/runninglinuxkernel_5.0/rlk_5.0/fs/ext2/inode.c"
LINES: "330-347"
TITLE: "ext2_find_goal"
FONT_SIZE: 12
COMMENTS:
  341: |-
    ```ad-translate
    heuristic: 启发式
    ```
    ==在上次分配的index和该index连续，最好在其附近(后面)分配物理块==
```

# ext2_find_near
##  ext2_find_near -- 代码注释
```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/runninglinuxkernel_5.0/rlk_5.0/fs/ext2/inode.c"
LINES: "274-292"
TITLE: "ext2_find_near"
FONT_SIZE: 12
COMMENTS:
  282: |-
    三条启发式算法(优先级依次向下)
    * 找该块的block entry前面的block entry(left),尽量让连续的index在物理块上也连续.
    * 找该块的block entry所在的间接块的相邻的块, 这样在间接索引中磁头移动最小.
      (`indirect block:n-> data_block:n+1`)
    * 如果指针位于 inode 本身，并且是第一个分配的。则在和 inode的同一柱面组
      （cylinder group）中分配，并用进程 PID 做颜色偏移，避免同组不同 inode 的并发分
      配冲突
      
    ==我们总结下原则:
    1.块的分配尽量和inode分配到统一柱面组,并且尽量用PID做染色偏移.(PID染色，其实是
      对访问同一个进程访问多个文件有利,作者认为在创建block时是同一个进程，那么在访问
      文件时，也可能是同一进程访问)
    2.如果是indirect block索引，尽量分配到indirect block附近
    3.尽量分配到逻辑index相邻的物理块==
```

## ext2_find_near -- code

```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/runninglinuxkernel_5.0/rlk_5.0/fs/ext2/inode.c"
LINES: "294-319"
TITLE: "ext2_find_near"
FONT_SIZE: 12
COMMENTS:
```

# ext2_blks_to_allocate

## ext2_blks_to_allocate -- code

```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/runninglinuxkernel_5.0/rlk_5.0/fs/ext2/inode.c"
LINES: "362-386"
TITLE: "ext2_blks_to_allocate"
FONT_SIZE: 12
COMMENTS:
  362: |-
    [[ext2_code#ext2_get_blocks -- code part4|caller]]
  367: |-
    [t, d] 应该是表示[start, end]
    注释中也提到, k表示还有未分配的indirect block。所以从`[blks, blocks_to_boundary]`都未分配,
  380: |-
    走到这里表示没有未分配的indirect block，所以有两种可能:
    + direct map
    + indirect map，但是最后一级的indirect block 已经分配
      
    所以这也就意味着，这个map block 已经被 =="其他人看到"==, 某些entry 可能已经被分配了。所以，
    我们应该检测下，哪些块已经被分配了。(不计数这些已经被分配的block)
```

# ext2_alloc_blocks
## ext2_alloc_blocks -- code
```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/runninglinuxkernel_5.0/rlk_5.0/fs/ext2/inode.c"
LINES: "398-449"
TITLE: "ext2_alloc_blocks"
FONT_SIZE: 12
COMMENTS:
  398: |-
    [[ext2_code#ext2_get_blocks -- code part4|caller]]
  421: |-
    该函数会尝试在`goal`附近获取 count 个块，并返回 current_block(physical block index),
    另外函数是`best-effort basic`, 既不保证能在`goal`处获取到块，也不保证能获取count个。获取的
    数量以count再作为出参传出
  426: |-
    为什么这里要写一个while(1)循环。那先来看下循环条件
    * 首先如果`new_blocks[]`未将 indirect blk 都填充(`index < indirect_blks && --count == 0`)
      则继续循环，如果下一轮循环未获取到数据块，则 failed_out
    * 如果 `new_block[]` 刚刚填充满(还未填充一个data block), 和上面一样。
    * 如果 `new_block[]` 被填充满，并且还剩余一个以上的data block ，将 第一个 data block index 填充到
      `new_block[]`, 这时再432 行判断 `count > 0` 退出循环
      
    ok, 总结下:
    * 获取block 数量(循环获取) 不到 `indirect_blks + 1(1个data block)` 退出循环, 并返回失败
    * 获取block 数量只要满足了`indirect_blk + 1`, 则不在继续获取block，退出循环
      
    原因是, 必须满足一个data block的分配, (当然能满足一个data block分配的前提是 indirect
    block必须分配成功)。 indirect block不一定和 data block连续, data block必须是连续的。
    ==所以，indirect block 之间以及 indirect block 和datablock 分配不比在一轮循环中(一次
    ext2_new_blocks()调用中获取，但是datablock的分配必须在一轮循环中分配)==
    见==1.==
  436: |-
    上面的循环只是赋值了`new_blocks[]`中的 indirect_blks, 但是并没有填充 direct blocks
```

1. 关于`new_blocks[]`数组的作用，以及为什么数组大小为4, 图片
   ![[new_blocks params in ext2_alloc_blocks.excalidraw|500]]
# ext2_alloc_branch
##  ext2_alloc_branch -- code
```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/runninglinuxkernel_5.0/rlk_5.0/fs/ext2/inode.c"
LINES: "476-543"
TITLE: "ext2_alloc_branch"
FONT_SIZE: 12
COMMENTS:
  493: |-
    `branch[0]`为在inode中，不用buffer read读取，所以这里可以直接赋值
  503: |-
    **new_blocks[n] 存储的是的是第n层间接块**
  510: 新分配出的block作为间接块时，应该全部先清零
  513: 赋值 indirect block entry
  514: |-
    如果是填充到最后一层 indirect blks entry, 513行已经填充了一个direct blk entry，
    下面的循环就是将剩余的direct blk entry填充为 data block index
  524: 表示该数据是可信的，有效的。个人感觉不必从磁盘中`sb_getblk()` indirect block，
       毕竟后续也是被`memset()`
       ```ad-todo
       个人猜测bh的生成机制是不是只有这一种。
       ```
  525: hb为当前层的indirect blks，其被清空后被赋值一项或多项，所以其需要mark dirty
  534: blks 用来存储分配的数据块的数量
```

![[ext2_alloc_branch.excalidraw|600]]