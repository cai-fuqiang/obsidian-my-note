
> [!PDF|note] [[sosp2023-pvm-paper.pdf#page=5&selection=352,36,376,14&color=note|📖|最坏情况下 一阶段 PF world switch 次数]]
> > In the first phase, 𝐿0 can be involved up to 2𝑛 + 2 times with 4𝑛 + 4 world switches
> 
> $4n+4 = 4(n+1)$
> * $n$表示页面的level number
> * $4$表示每次触发`#PF`要触发4次world switch
> * $1$表示 L2 userspace 触发 `#PF`, hypervisor 转发到 L2
> ```ad-question
>  但是似乎，这个结论并不准确，举个例子, 当guest 触发`#PF`时, 该 GPA 在GPT的4-level page table中, 只有前两级有映射, 此时 3th GPT 中关于该GPA的 page table entry 为 not present, 此时，L2 PF handler 分配一个page, 作为 4th GPT。而此时 L1并不能识别到这个page 是 GPT, 当 L2 PF handler又分配了一个PAGE作为最终的GVA的GPA所在的页。并填充 4th GPT时，GPT 并不是WP。所以，并不能达到文章中所提到的 $4n+4$
> ```

> [!PDF|yellow] [[sosp2023-pvm-paper.pdf#page=5&selection=450,40,481,1&color=yellow|📖 最差的情况下L1, L2更新的总次数]]
> > in which both GPT2 and SPT12 need to be updated, and assuming an nlevel GPT2, an 𝐿2 page fault can lead to 4n + 8 world switches and 2n + 4 exits to 𝐿0.
> 
> 由于二阶段也会产生一次PF, 所以在此基础上+1即:
> * $4n + 8 = 4(n+1+1)$
> * $2n + 4 = 2(n+1+1)$