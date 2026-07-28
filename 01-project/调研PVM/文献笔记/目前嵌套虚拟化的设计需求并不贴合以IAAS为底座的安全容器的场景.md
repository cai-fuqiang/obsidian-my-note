
> [!PDF|important] [[sosp2023-pvm-paper.pdf#page=6&selection=117,0,117,5&color=important|📖 目前嵌套虚拟化的设计需求并不贴合以IAAS为底座的安全容器的场景]]
> 目前嵌套虚拟化的设计需求: **按照==完全虚拟化需求==设计**,  完全虚拟化的优点 [[sosp2023-pvm-paper.pdf#page=6&selection=118,35,127,1|兼容性好]], 无需额外修改L1 guest kernel. 
> 但是这个设计需求（或者说总目标）在安全容器下完全不需要。**安全容器对底座的要求，是渴望提供一个==高性能, [[sosp2023-pvm-paper.pdf#page=6&selection=135,2,135,35|强隔离]]==的运行环境, 其不关心运行底座（L1)，以及 Guest Kernel<sub>L2</sub>**, 并且期望运行在[[sosp2023-pvm-paper.pdf#page=6&selection=136,31,136,57|任意厂商云底座]]中
