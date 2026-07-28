> [!PDF|note] [[sosp2023-pvm-paper.pdf#page=2&selection=84,6,109,19&color=note|嵌套虚拟化实现的方法之二: 在L0维护一个 "压缩的" EPT 来转换 GPA(L2)->HPA(L0) ]]
> > A more popular and the default approach in KVM [20] is to allow the 𝐿2 guest to use its own page table while the 𝐿0 hypervisor maintains a compressed EPT or NPT for translating 𝐿2 guest physical addresses to 𝐿0 physical addresses (the bottom two levels).
> 
