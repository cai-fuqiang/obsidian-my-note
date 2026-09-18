---
type: literature
status: reading
category:
summary: 关键信息有：<br/>1. 各层gpte的 ptes
created: 2026-09-15T21:10:37+08:00
modified: 2026-09-15T22:24:40+08:00
QA:
---
# summary

> [!summary]
> `= this.summary`

# 引用
| 成员              | 作用                                                                                      | 如果是数组，数组长度         |
| --------------- | --------------------------------------------------------------------------------------- | ------------------ |
| level           | 作为`walk_addr`出参，GPT遍历到哪一级中断了                                                            |                    |
| max_level       | 表示GPT的最大层级(5-level or 4-level or other)                                                 |                    |
| table_gfn[]     | per level  GPT的guest pfn                                                                | PT_MAX_FULL_LEVELS |
| pte_gpa[]       | table_gfn[] gfn对应具体index的**pte entry ==gpa==** (即 table_gfn[] +index_offset)            | PT_MAX_FULL_LEVELS |
| ptep_user[]     | pte_gpa[] 对应的 hva（需要通过memslot查找 gfn_to_hva)                                             | PT_MAX_FULL_LEVELS |
| ptes[]          | ptep_user[] 存储的ptes(`get_user(ptep_user[])`)                                            | PT_MAX_FULL_LEVELS |
| prefetch_ptes[] |                                                                                         | PTE_PREFETCH_NUM   |
| pte_writable[]  | ptep_user[] hva所在的memslot是否可写                                                           | PT_MAX_FULL_LEVELS |
| pt_access[]     | table_gfn[] 的页的access right，**这个access right 是根据前面level 综合计算得到 **                       | PT_MAX_FULL_LEVELS |
| pte_access      | 最后一级GPT中关于该addr 的pte entry access right, 和 pt_access[]相同，也是根据前面level综合计算得到              |                    |
| gfn             | 经过完整的GPT walk 的到的gfn的具体值                                                                |                    |
| fault           | 因 GPT walk 所造成的异常，例如去写 一个wp的page(wp指GPT本身指示WP attr)。或者是 page table walk 因not present 中断 |                    |

> [!note] `L1 EPT`以及 `L2 GPT` 我们这里统称为 GPT
# related

## 可提炼的永久笔记
- [ ]
## 其他引用笔记

# TODO