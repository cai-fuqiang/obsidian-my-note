
> [!PDF|yellow] [[sosp2023-pvm-paper.pdf#page=6&selection=170,12,176,6&color=yellow|📖 PVM 设计简述]]
> 
>  * **L2只运行于VMX non-root operation Ring 3** : ==[[sosp2023-pvm-paper.pdf#page=6&selection=257,0,271,12|📖 L2 只运行在 Ring 3]]==,  [[sosp2023-pvm-paper.pdf#page=6&selection=271,13,272,51|📖 特权级的隔离通过 使用不同的页表]] , [[sosp2023-pvm-paper.pdf#page=6&selection=272,52,277,43|📖 这样做的好处是保证隔离性的同时，提升了 world switch 的效率]]
>  *  **提升world switch 性能** : **==[[sosp2023-pvm-paper.pdf#page=6&selection=278,2,305,1|📖 L2 运行在 Ring3 能让L1 直接接收来自于L2的所有特权指令的访问，避免trap 到L0]]==**,  同时 [[sosp2023-pvm-paper.pdf#page=6&selection=306,0,324,36|📖 PVM也为L1, L2的切换构建了一段高效的汇编代码]]
>  * **高效的内存虚拟化算法** [[sosp2023-pvm-paper.pdf#page=6&selection=327,0,336,30|📖 在影子页表方面， PVM 也设计了一套高效的算法, 性能比 EPT-on-EPT 要高]]
