
> [!PDF|note] [[sosp2023-pvm-paper.pdf#page=5&selection=324,0,351,32&color=note|📖 SPT readonly使world switch 次数更多]]
> > every update to GPT2 needs assistance from 𝐿1. Hence, step ➇ could further cause multiple rounds of switches between 𝐿2 and 𝐿1 via 𝐿0 (not illustrated in Figure 3(a)), depending on the number of page table levels.
> 
> 因为GPT2 是READ-ONLY的，也就是说。L2 page fault handler 每次因缺页更新每一级GPT都会触发多轮次的 前面提到的一阶段流程。这个多轮次的中的轮次和多种因素有关:
> * Numbers of Guest Page Table level
> * Only Need update missing level . 越靠前的page table level 覆盖的address range越大。可能之前的PF 已经在前面的level中填充好了 相应的entry，本次PF L2 kernel 会考虑直接使用该entry，而不modify，所以只需填充(write) 后面几级not present（甚至最后一级）的 page table entry.
