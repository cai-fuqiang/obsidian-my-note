
> [!PDF|yellow] [[sosp2023-pvm-paper.pdf#page=5&selection=414,31,449,1&color=yellow|📖 二阶段和一阶段的不同点]]
> > First, at step ➍ the 𝐿1 kernel handles the page fault and updates SPT12. Second, step ➐ returns directly to 𝐿2 user space without involving the 𝐿2 guest kernel. In the second phase, there are four more world switches, including trapping to 𝐿0 twice.
> 
> 二阶段和一阶段有两方面不同:
> * 步骤➍ 处理PF时，会更新 `SPT12`
> * 步骤➐ 直接返回L2 的userspace 而不是L2 Guest kernel.
