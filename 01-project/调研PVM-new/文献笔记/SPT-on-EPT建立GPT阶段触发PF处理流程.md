
> [!PDF|yellow] [[sosp2023-pvm-paper.pdf#page=4&selection=448,16,453,7&color=yellow|📖SPT-on-EPT建立GPT阶段触发#PF处理流程]]
> > More specifically, in the first phase, an access to an absent GVA𝐿2 in GPT2
> 
> 在第一个阶段由于 L2 GPT还未建立完全, L2访问GVA<sub>L2</sub>触发缺页,  该缺页最终需要 `hypervisor` 将 PF的结果 "原样"(其实也就是CR2即触发PF的虚拟地址) 转发到L2, 然而这个流程在nested virtualization中特别费劲
> 1. GPT2 trigger L2 pagefault 并且切换到L0 (➀)
> 2. L0 通过写 VMCS<sub>01</sub> 将 该 PF注入到 L1(➁), 并且切换到L1(➂)
> 3. L1 收到了这是L2 page fault 通过写VMCS<sub>12</sub> 将 PF 预转发到L1(➃) , 并且恢复L2执行.但是恢复L2执行类似于vmresume指令，会先trap到L0(➄)
> 4. L0 在VMCS<sub>12</sub>中发现了PF 注入请求，并将其写入VMCS<sub>02</sub>(➆)
> 5. L0 使用 VMCS<sub>02</sub>恢复L2(➆).
> 6. L2 page fault handler 使用这个刚刚建立映射的新page 建立GVA<sub>L2</sub>->GPA<sub>L2</sub>的映射(➇)
> 7. L2 kernel 返回用户态(➈)
> 
> 整个过程涉及world switch 次数
> * L2->L0(1)
> * L1->L0(1)
> * L0->L1(2)
> 
> 共四次
