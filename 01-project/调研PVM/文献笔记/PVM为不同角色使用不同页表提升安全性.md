
> [!PDF|yellow] [[sosp2023-pvm-paper.pdf#page=7&selection=229,0,235,6&color=yellow| 📖  PVM 使用类似于 kernel KPTI的机制 来增强安全性]]
> 主要用来缓解类似于 Meltdown 和 Spectre 之类的攻击.

> [!PDF|yellow] [[sosp2023-pvm-paper.pdf#page=7&selection=349,16,381,2&color=yellow|📖  PVM 使用类 KPTI机制的最主要的实现: 将L1 host kernel 和 L2 guest 使用单独页表]]
> >  Similar to KPTI, PVM leverages separate page tables for the 𝐿1 host kernel (i.e., the guest hypervisor) and the 𝐿2 guest and consolidates the switcher’s code/data (e.g., syscall entry, IDT, TSS, trampoline stack, LDT, etc.) accessed by both the 𝐿1 hypervisor and the 𝐿2 guest in a perCPU entry area. 
> 

> [!PDF|note] [[sosp2023-pvm-paper.pdf#page=7&selection=381,2,391,23&color=note|📖 另外 PVM 也为L2 guest user 和 kernel 使用两套页表]]