---
title: "ext2_alloc_blocks解析-CSDN博客"
source: "https://blog.csdn.net/kai_ding/article/details/9747223"
author:
  - "[[成就一亿技术人!]]"
  - "[[hope_wisdom 发出的红包]]"
published:
created: 2026-06-26
description: "文章浏览阅读1.3k次。本文详细解析了ext2文件系统中磁盘块分配函数ext2_alloc_blocks的工作原理，阐述了如何分配间接块和直接数据块，并确保至少一个数据块连续。通过具体示例说明了函数的执行流程。"
tags:
  - "clippings"
---
在之前我们分析的ext2\_allocate\_branch()函数中，我们说到其第一步可能也是最重要的一步就是分配磁盘块，这个磁盘块包括间接块和直接数据块，没有物理磁盘块，一切都只是空谈，而分配物理磁盘块调用的是函数ext2\_alloc\_blocks，这里我们就来重点分析下分配物理磁盘块的过程。

在分析这个函数之前，我们必须明白一点的是：这里所分配的磁盘块既包含间接索引块也包含直接数据块（如果真的需要使用到间接索引的话）。而且，这个函数保证一点：分配所有的间接块以及最少一个数据块，而且分配的数据块必定连续，但索引块无法保证在磁盘块号上连续。

```cpp
static int ext2_alloc_blocks(struct inode *inode,
            ext2_fsblk_t goal, int indirect_blks, int blks,
            ext2_fsblk_t new_blocks[4], int *err)

{
    int target, i;
    unsigned long count = 0;
    int index = 0;
    ext2_fsblk_t current_block = 0;
    int ret = 0;
 
    /*
     * Here we try to allocate the requested multiple blocks at once,
     * on a best-effort basis.
     * To build a branch, we should allocate blocks for
     * the indirect blocks(if not allocated yet), and at least
     * the first direct block of this branch.  That's the
     * minimum number of blocks need to allocate(required)
     */
    target = blks + indirect_blks;

    while (1) {
        count = target;
        /* allocating blocks for indirect blocks and direct blocks */
        /* 这里分配的磁盘块一定连续
        */
        current_block = ext2_new_blocks(inode,goal,&count,err);
        if (*err)
            goto failed_out;

        target -= count;
        /* allocate blocks for indirect blocks */
        /* 记录分配的间接索引块的物理块号在
        ** 结果数组的前N 项
        */
        while (index < indirect_blks && count) {
            new_blocks[index++] = current_block++;
            count--;
        }

        /* count > 0 意味着间接块已经分配好了，而且
        ** 至少分配了一个直接数据块，此时达到了
        ** 我们对外提供的保证，可以返回
        ** 注意:  这里分配的直接数据块一定连续
        */

        if (count > 0)
            break;
    }

    /* save the new block number for the first direct block */
    new_blocks[index] = current_block;
    /* total number of blocks allocated for direct blocks */
    ret = count;
    *err = 0;
    return ret;
failed_out:
    for (i = 0; i <index; i++)
        ext2_free_blocks(inode, new_blocks[i], 1);
    if (index)
        mark_inode_dirty(inode);
    return ret;

}
cpp
```
我们首先看看该函数的参数：
1. inode：代表了需要分配磁盘块的文件；
2. goal：上层调用者给出的建议分配磁盘块号；
3. indirect\_blks：需要分配的间接块的数目；
4. new\_blocks\[4\]：分配的磁盘块号存储的地方，作为分配结果返回给调用者；
5. err：分配过程中的错误码。

这里需要解释的参数是new\_blocks\[4\]，可能会有人觉得很奇怪，为什么只需要4项就可以记录返回结果呢？假如我需要分配的间接块+直接数据块的数目远大于4该怎么办？关于这点其实在我之前的博客中也有提及，那就是：1. 首先ext2文件系统的设计决定每次最多分配的间接块的数目为3（因为最多只有三级索引），而ext2\_allocate\_blocks()在实现的时候**<mark style="background:#fdbfff">无法保证分配的间接块在磁盘上连续，所以最多需要3项才能记录间接块的分配结果</mark>**；2. **ext2\_allocate\_blocks()==保证分配的直接数据块在磁盘上连续==，因为它只是尽力分配，==不一定会分配到你想要的那么多的数据块==，有可能只会给你返回1个直接数据块，即使你想要分配100个直接数据块，但它能保证分配到的数据块在磁盘上连续，因此，对于直接数据块==只需要一项纪录其起始块号即可==。**

好了，现在让我们回头来看看该函数的具体实现，流程说起来是相对比较简单：

1. 调用ext2\_new\_blocks()来分配想要数量的磁盘块，==但该函数返回的磁盘块数量不一定就是你想要的，但其返回的磁盘块一定连续；==
2. 将1中分配的磁盘块记录在返回结果中，首先将间接块号记录在返回结果（数组）的前几项；
3. 判断所需数量的间接块是否分配完成，如果已完成并且直接数据块的数量还大于1，那么就可以返回了。我不保证你需要多少我就分配多少，我只保证1.分配了你想要数量的间接块，2. 至少分配一个直接数据块。
4. 如果间接块数量还未分配够，或者间接块数量已经足够但还未分配直接数据块，那么转步骤1继续分配。

不妨举个例子，假如我要分配3个间接块，10个直接数据块。现在调用该函数，在函数的第一轮循环中，我只分配了2个空闲块（块号500,501，一定连续），那首先将这两个空闲块作为间接块，块号保存在new\_blocks\[0\]和new\_blocks\[1\]中，因为我们需要3个间接块，而目前只分配了两个，无法满足要求，所以还得继续下一轮分配。

在第二轮分配中，假如通过ext2\_new\_blocks分配到了5个空闲块（块号651， 652， 653，654，655）此时，将第一个空闲块651作为间接块存储在new\_blocks\[3\]中，而接下来的空闲块652记录在new\_blocks\[4\]中，且将分配到的直接数据块数量4作为返回值告知调用者。

因为此时已经达到了我们的保证（分配所有的间接块以及至少一个直接数据块），所以无需再继续下去了，函数直接返回即可。其中new\_blocks\[1 ~ 3\]存储的是分配的间接块号，new\_blocks\[4\]中存储的是分配到的直接数据块起始块号，且直接数据块数量也通过返回值传递给调用者了。

至此，我们对于ext2\_allocate\_blocks()的分析就落下帷幕了，这个函数依赖ext2\_new\_blocks()的实现，这将是我们在下一篇博客中的主要任务。