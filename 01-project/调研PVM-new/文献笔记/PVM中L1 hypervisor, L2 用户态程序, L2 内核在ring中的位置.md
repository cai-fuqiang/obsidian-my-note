
> [!PDF|note] [[sosp2023-pvm-paper.pdf#page=6&selection=403,12,436,22&color=note|📖 PVM中L1 hypervisor, L2 用户态程序, L2 内核在ring中的位置]]
> 
> * L2 完全运行在 Ring3 中（即 h_ring3 in non-root mode)
>    + 在 v_ring3 中运行安全容器(用户态程序)
>    + 在 v_ring0 中运行 **==半虚拟化== kernel**
> * 为了将在 h_ring3 中的 v_ring0和v_ring1 区分，使用 ==独立的page 隔离== L2 guest 和 kernel
> ![[sosp2023-pvm-paper.pdf#page=6&rect=340,560,532,737&color=note|400]]

