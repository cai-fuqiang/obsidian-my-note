
> [!PDF|important] [[sosp2023-pvm-paper.pdf#page=7&selection=194,32,216,18&color=important|📖 switcher 需要在多个地址空间中映射相同地址原因]]
> > To be executed across domains during the switchover process (i.e., involving switching page tables and address spaces), switcher must be located at identical virtual addresses in the 𝐿2 user, 𝐿2 kernel, and 𝐿1 guest hypervisor. 
> 
> **switcher 代码本身涉及==跨域(地址空间)执行==** -- 切换页表和地址空间. 切换后，还得保证代码能**继续执行**。所以需要保证，切换后的地址空间中有映射(没有映射就触发PF了)，另外，还得是相同映射（否则本来连续执行的指令就跑飞了)
> ```ad-faq
> Q: 和谁很像呢？
> A: **kernel context switch**
> kernel 在切换进程时，涉及两个地址空间的切换。kernel context switch 其实就是一个switcher，其需要在两个地址空间中拥有相同的地址
> ```

