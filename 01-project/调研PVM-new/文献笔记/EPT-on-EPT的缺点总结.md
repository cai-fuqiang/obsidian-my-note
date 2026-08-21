
> [!PDF|yellow] [[sosp2023-pvm-paper.pdf#page=6&selection=32,0,32,5&color=yellow|📖 EPT-on-EPT(或者说靠硬件辅助内存虚拟化)的缺点总结]]
> * [[sosp2023-pvm-paper.pdf#page=6&selection=32,7,34,4| 性能损耗过大]] : 仍然有大量的world switch导致性能损耗过大
> * [[EPT-on-EPT 的性能损耗，会随着测试并发数量增加而增加]] ==**（关键)**==
> * [[sosp2023-pvm-paper.pdf#page=6&selection=54,9,60,3|依赖L0暴露EPT给L1]] : 增加了L0的复杂度，并且降低了cloud stack的灵活性，例如:
>    *  [[sosp2023-pvm-paper.pdf#page=6&selection=62,12,74,18|如果有L2的虚拟机，L1 不能 migrate, saved load]]
>    * [[sosp2023-pvm-paper.pdf#page=6&selection=74,20,87,1|很多云厂商不支持嵌套虚拟化/或者在支持嵌套虚拟化上有一些限制]]（例如不支持机密计算)
>    * [[sosp2023-pvm-paper.pdf#page=6&selection=98,3,104,11|EPT-on-EPT严重依赖L0, 这会让 L0 hyper 变胖，降低安全性]]
