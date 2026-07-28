
> [!PDF|yellow] [[sosp2023-pvm-paper.pdf#page=7&selection=144,0,144,5&color=yellow|📖 switcher 仿照 xen / lguest 等现有半虚拟化 架构设计，并做了改进]]
>  * **借鉴前辈**:
>     + [[sosp2023-pvm-paper.pdf#page=7&selection=147,39,152,2|📖 仿照 最新的 xen 将 guest user 和 kernel 都放置在 L3]], 原因是 [[sosp2023-pvm-paper.pdf#page=7&selection=153,31,158,33|📖后续的 intel cpu 可能要删除ring1并限制segment feature]]
>     + [[sosp2023-pvm-paper.pdf#page=7&selection=163,50,179,40&color=note|📖 借鉴 lguest/xen等架构 实现switcher]]
>     + [[sosp2023-pvm-paper.pdf#page=7&selection=216,19,228,11&color=note|📖 将switcher 代码放到高地址空间，用户和内核都可以用相同的页表访问]]
>  * **超越前辈**: 
>     + [[PVM为不同角色使用不同页表提升安全性]]
> 	    + host L1 kernel && L2 guest
> 	    + L2 guest user && L2 guest kernel