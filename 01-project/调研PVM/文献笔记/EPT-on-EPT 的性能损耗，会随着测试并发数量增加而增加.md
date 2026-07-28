> [!PDF|important] [[sosp2023-pvm-paper.pdf#page=5&selection=713,6,716,10&color=important|📖 EPT-on-EPT 的性能损耗，会随着测试并发数量增加而增加]]
> >  However, a considerable performance gap persisted between EPT-on-EPT and single-level memory virtualization (EPT only), and this gap widened as concurrency levels increased.
> 
> 这是作者一个非常重要的测试结果:
> **EPT-on-EPT体现出了 ==并发量上的不可扩展性==**