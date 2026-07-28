
> [!PDF|note] [[sosp2023-pvm-paper.pdf#page=5&selection=582,45,608,26&color=note|📖 EPT-on-EPT第一阶段: 构建 EPT12]]
> >  The first phase updates EPT12 and EPT01 (➊-➓). The update of EPT12 is emulated by 𝐿0 – by making EPT12 read-only to 𝐿1. Hence, step ➎-➐ may repeat multiple times 
> 
> 和SPT-on-EPT类似，由于 EPT12是`read-only`, 仍然需要多次重复多次切换