> [!summary] syscall/sysret 用作快速的系统调用

> [!question]  为什么syscall, sysret 的性能要好很多 ?
>  我个人认为是因为 syscall/sysret 指令实现中, 会避免访问内存 [[int0x80_vs_syscall.excalidraw|int 0x80 只少访问三次内存]]

> [!PDF|] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3165&selection=48,21,49,93|📖 syscall,sysret 只能用于IA-32e mode operation, 不能用于 compatibility mode(protect mode)]]
> > The instructions, along with SYSENTER and SYSEXIT, are suited for IA-32e mode operation. SYSCALL and SYSRET, however, are not supported in compatibility mode (or in protected mode). 

> [!PDF|] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3165&selection=54,0,54,85|📖 SYSCALL/SYSRET 中的stack pointer不能通过MSR指定，需要操作系统软件自己切换]]
> > Stack pointers for SYSCALL/SYSRET are not specified through model specific registers.
> 

> [!PDF|] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3165&selection=51,0,53,64|📖 syscall 用于从用户态代码(ring 3)切换到 操作系统代码(ring 0), 反之亦然]]
> > **SYSCALL** is intended for use by **user code running at privilege level ==3== to access operating system or executive procedures running at privilege level ==0==**.  **SYSRET** is intended for use by **privilege level ==0== operating system or executive procedures for fast returns to privilege level ==3== user code**.

> [!PDF|] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3165&selection=56,0,56,95|📖 调用syscall SAVE user上下文:]]
> > For SYSCALL, the processor saves RFLAGS into R11 and the RIP of the next instruction into RCX; 
> * RFLAGS->R11
> * RIP->RCX

> [!PDF|] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=1900&selection=16,4,21,74| 📖 CS, SS selector会从IA32_STAR 中获取，但是 CS, SS desc 不会从GPT/LDT 中获取]]
> > ALL loads the CS and SS selectors with values derived from bits 47:32 of the IA32_STAR MSR. However, the **CS and SS descriptor caches are ==not loaded== from the descriptors (in GDT or LDT) referenced by those selectors**.

> [!PDF|] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3165&selection=56,95,57,96|📖 调用syscall STORE host上下文]]
> * CS <-  `IA32_STAR[47:32]`
> * RIP <- IA32_LSTAR
> * SS <- `IA32_STAR[47:32]+ 8`
> * RFLAGS <- old_rflags & IA32_FMASK

> [!PDF|] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=1900&selection=46,0,46,9|📖 syscall 伪代码]]

> [!summary] syscall的调用过程中，未访问一次内存