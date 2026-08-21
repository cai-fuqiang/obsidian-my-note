> [!PDF|important] [[sosp2023-pvm-paper.pdf#page=5&selection=609,38,634,43&color=important|📖 EPT-on-EPT 第一阶段 比 SPT-on-EPT 第一阶段 world switch次数减少接近一倍]]
> > Thus, the first phase traps to 𝐿0 𝑛 + 2 times with 2𝑛 + 4 world switches (where 𝑛 is the number of EPT12 page table levels). 
> 
> * trap: $2(n+1)$  --> $n+2$
> * world switch: $4(n+1)$ --> $2(n+2)$
> 其并不是成比例的关系，我们以Trap视角来看:
> * n: 每访问一次 EPT<sub>12</sub> 因WP触发trap (➎-➐)
>   * 1: L2 userspace 访问 GVA<sub>L2</sub>时, 触发 EPT voliation, trap L0 (❶❸)
>   * 1: L1 resume L0时，需要trap L0 (❽❿)

> [!PDF|note] [[sosp2023-pvm-paper.pdf#page=5&selection=644,35,657,21&color=note|📖 EPT-on-EPT 第二阶段 比 SPT-on-EPT trap 次数减少一倍]]
> > it adds one more 𝐿0 trap and two more world switches. 
> 
> EPT-on-EPT 第二阶段仅仅只Trap一次.

> [!PDF|yellow] [[sosp2023-pvm-paper.pdf#page=5&selection=684,0,693,2&color=yellow|📖 结论: SPT-on-EPT比 EPT-on-EPT 会多更多的 world switch 次数]]
> > Compared to SPT-on-EPT, EPT-on-EPT is more efficient in terms of fewer number of world switches and 𝐿0 traps [ 13].
