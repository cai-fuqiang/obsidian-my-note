
# 24.2 VIRTUAL MACHINE ARCHITECTURE

> [!PDF|note] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3924&selection=31,0,38,68&color=note|📖]]
> > Virtual-machine monitors (VMM) — A VMM acts as a host and has full control of the processor(s) and other platform hardware. A VMM presents guest software (see next paragraph) with an abstraction of a virtual processor and allows it to execute directly on a logical processor. A VMM is able to retain selective control of processor resources, physical memory, interrupt management, and I/O.
> 
> VMM 一方面为guest software 准备一个抽象的vcpu，让guest software 可以执行运行在logical
> processor 。另一方面，其也会控制某些系统资源，例如 memory, interrupt, I/O.

> [!PDF|note] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3924&selection=42,0,48,109&color=note|p.3924]]
> > Guest software — Each virtual machine (VM) is a guest software environment that supports a stack consisting of operating system (OS) and application software. Each operates independently of other virtual machines and uses on the same interface to processor(s), memory, storage, graphics, and I/O provided by a physical platform. The software stack acts as if it were running on a platform with no VMM. Software executing in a virtual machine must operate with reduced privilege so that the VMM can retain control of platform resources.
> 
> Guest software 其架构和在物理机上的软件架构一样包括:
> * OS
> * application software
> 在guest software 看来，其就像运行在物理机上一样，拥有对process, memory storage等等硬件相同的操作接口。
> 但是, guest software 在运行时，权限会降低，这样VMM才能控制平台资源


# 24.3 INTRODUCTION TO VMX OPERATION

> [!PDF|important] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3924&selection=54,104,55,73&color=important|325462-sdm-vol-1-2abcd-3abcd-4, p.3924]]
> > There are two kinds of VMX operation: VMX root operation and VMX non-root operation
> 
> 在支持VMX operation 后，运行的模式有下面几种:
> * VMX operation
> 	+ VMX root operation
> 	+ VMX non-root operation
> * outside VMX operation
> 

> [!PDF|important] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3924&selection=57,50,59,8&color=important|📖]]
> >  There are two kinds of VMX transitions. Transitions into VMX non-root operation are called VM entries. Transitions from VMX non-root operation to VMX root operation are called VM exits
> 
> 两个模式切换操作。

> [!PDF|translate] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3924&selection=60,0,62,48&color=translate|325462-sdm-vol-1-2abcd-3abcd-4, p.3924]]
> > Processor behavior in VMX root operation is very much as it is outside VMX operation. The principal differences are that a set of new instructions (the VMX instructions) is available and that the values that can be loaded into certain control registers are limited (see Section 24.8)
> 
> VMX root operation 和 outside VMX operation 非常像。但是:
> * VMX root operation 中有支持一组新的instruction VMX instructions
> * 某些控制寄存器在VMX root operation 值会被限制。（也就是进入VMX root operation必须设置控制寄存器的某些bit 为某个值)


> [!PDF|red] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3924&selection=67,0,67,114&color=red|325462-sdm-vol-1-2abcd-3abcd-4, p.3924]]
> > There is no software-visible bit whose setting indicates whether a logical processor is in VMX non-root operation.
> 
> guest 没有办法能看出来自己运行在VMX non-root operations

> [!PDF|translate] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3924&selection=69,0,71,16&color=translate|325462-sdm-vol-1-2abcd-3abcd-4, p.3924]]
> > Because VMX operation places restrictions even on software running with current privilege level (CPL) 0, guest software can run at the privilege level for which it was originally designed. This capability may simplify the development of a VMM.
> 
> 这段我一开始没有看懂。。。他的意思是，即便是guest运行在CPL 0 也会受限制。所以可以让guest放心运行在CPL0。这样guest软件架构就无需变动。(和运行在物理机一样)

# 24.4 LIFE CYCLE OF VMM SOFTWARE

> [!PDF|note] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3925&selection=5,0,7,26&color=note|325462-sdm-vol-1-2abcd-3abcd-4, p.3925]]
> > 24.4 LIFE CYCLE OF VMM SOFTWARE
> 
> 有两种类型的切换:
> * VMX (root) operation -- outside VMX operation: `VMXON` ,`VMXOFF`
> * VMX root operation -- VMX non root operation: `VM Entry`, `VM Exit`


> [!PDF|note] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3925&selection=23,0,23,64&color=note|325462-sdm-vol-1-2abcd-3abcd-4, p.3925]]
> > VM exits transfer control to an entry point specified by the VMM
> 
> 退出的地址是由VMM 指定的入口

单词翻译:
> [!PDF|translate] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3925&selection=9,86,9,98&color=note|325462-sdm-vol-1-2abcd-3abcd-4, p.3925]]
> > interactions
> 
> 互动

> [!PDF|translate] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3925&selection=23,90,23,101&color=translate|325462-sdm-vol-1-2abcd-3abcd-4, p.3925]]
> > appropriate
> 
> 合适的

> [!PDF|translate] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3925&selection=28,24,28,30&color=translate|325462-sdm-vol-1-2abcd-3abcd-4, p.3925]]
> > decide
> 
> 决定

# 24.5 VIRTUAL-MACHINE CONTROL STRUCTURE

> [!PDF|important] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3925&selection=35,0,36,17&color=important|325462-sdm-vol-1-2abcd-3abcd-4, p.3925]]
> > VMX non-root operation and VMX transitions are controlled by a data structure called a virtual-machine control structure (VMCS).
> 
> VMCS 主要有两个功能:
> * **execution** VMX non-root operation
> * VMX transitions -- **save/restore** guest/host **CONTEXT**

> [!PDF|note] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3925&selection=37,0,40,21&color=note|325462-sdm-vol-1-2abcd-3abcd-4, p.3925]]
> > Access to the VMCS is managed through a component of processor state called the VMCS pointer (one per logical processor). The value of the VMCS pointer is the 64-bit address of the VMCS. The VMCS pointer is read and written using the instructions VMPTRST and VMPTRLD. The VMM configures a VMCS using the VMREAD, VMWRITE, and VMCLEAR instructions.
> 
> * 每个逻辑处理器状态包括一个指针 -- VMCS pointer(current VMCS pointer), 该指针是64-bit address，用来指向VMCS的地址
> * VMCS pointer 读写由 `VMREAD`, `VMWRITE` 来完成。
> * `VMREAD`, `VMWRITE`, `VMCLEAR`: 对 VMCS pointer指向的VMCS 操作。

> [!PDF|translate] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3925&selection=41,0,42,102&color=translate|325462-sdm-vol-1-2abcd-3abcd-4, p.3925]]
> > A VMM could use a different VMCS for each virtual machine that it supports. For a virtual machine with multiple logical processors (virtual processors), the VMM could use a different VMCS for each virtual processor
> 
> VMM为每个VM使用不同的的VMCS。每个VM的每个VCPU，VMM为其准备了不同的`VMCS`

单词翻译:

> [!PDF|translate] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3925&selection=37,40,37,49&color=translate|325462-sdm-vol-1-2abcd-3abcd-4, p.3925]]
> > component
> 
> 成分

# 24.6 DISCOVERING SUPPORT FOR VMX

> [!PDF|note] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3925&selection=44,0,46,27&color=note|325462-sdm-vol-1-2abcd-3abcd-4, p.3925]]
> > 24.6 DISCOVERING SUPPORT FOR VMX
> 
> 在进入VMX operation 之前，软件需要判断当前CPU是否支持VMX features，通过`CPUID.1:ECX.VMX[BIT 5]`
> 另外，后续的CPU会在VMX operation上增加一些额外的features， 这些features通过
> `VMX Capability MSR`报告

# 24.7 ENABLING AND ENTERING VMX OPERATION

> [!PDF|important] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3926&selection=9,0,10,50&color=important|325462-sdm-vol-1-2abcd-3abcd-4, p.3926]]
> > Before system software can enter VMX operation, it enables VMX by setting CR4.VMXE[bit 13] = 1. VMX operation is then entered by executing the VMXON instruction
> 
> 只有当`CR4.VMXE[bit13] = 1`时，才能使用VMXON instruction

> > [!PDF|note] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=4119&selection=19,0,20,8&color=note|325462-sdm-vol-1-2abcd-3abcd-4, p.4119]]
> > > IF (register operand) or (CR0.PE = 0) or (CR4.VMXE = 0) or (RFLAGS.VM = 1) or (IA32_EFER.LMA = 1 and CS.L = 0) THEN #UD
> > 
> > 上面的伪代码，当CR4.VMXE为0时，直接报 `#UD`


> [!PDF|important] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3926&selection=14,0,45,77&color=important|325462-sdm-vol-1-2abcd-3abcd-4, p.3926]]
> > VMXON is also controlled by the IA32_FEATURE_CONTROL MSR (MSR address 3AH). This MSR is cleared to zero when a logical processor is reset. The relevant bits of the MSR are: 
> > 
> > • Bit 0 is the lock bit. If this bit is clear, VMXON causes a general-protection exception. If the lock bit is set, WRMSR to this MSR causes a general-protection exception; the MSR cannot be modified until a power-up reset condition. System BIOS can use this bit to provide a setup option for BIOS to disable support for VMX. To enable VMX support in a platform, BIOS must set bit 1, bit 2, or both (see below), as well as the lock bit. 
> > • Bit 1 enables VMXON in SMX operation. If this bit is clear, execution of VMXON in SMX operation causes a general-protection exception. Attempts to set this bit on logical processors that do not support both VMX operation (see Section 24.6) and SMX operation (see Chapter 7, “Safer Mode Extensions Reference,” in the Intel® 64 and IA-32 Architectures Software Developer’s Manual, Volume 2D) cause general-protection exceptions. 
> > • Bit 2 enables VMXON outside SMX operation. If this bit is clear, execution of VMXON outside SMX operation causes a general-protection exception. Attempts to set this bit on logical processors that do not support VMX operation (see Section 24.6) cause general-protection exceptions.
> 

`VMXON`指令的行为受`IA32_FEATURE_CONTROL` MSR的前三位控制，该MSR会在logical processor reset的时候被clear。
* **bit 0**: lock bit. 如果lock bit被clear,  就说明还没有被锁定，在没有被锁定的情况下使用`VMXON`则会报`#GP`。而如果被置位，则再通过`WRMSR`写这个寄存器则会造成`#GP`.
* **bit 1**: 该bit用来控制是否能在`SMX`中执行`VMXON`。当其被clear时，在`SMX`中执行`VMXON`指令则会触发`#GP`.
* **bit 2**: 该bit用来控制是否能在`SMX`之外的mod中执行`VMXON`。当其被clear时,   在`outsize SMX`operation时，会触发`#GP`

总结下其作用：CPU期望使用者（可能是BIOS初始化程序) 先决定`VMXON` 在`SMX`,`outside SMX`模式中的执行权，决定完执行权后，设置`bit 0(lock bit)`。锁住该寄存器不能被其他程序（例如OS）修改。

一个例子就是，bios中的VMX开关，当用户关闭VMX时，BIOS可以按顺序设置
* bit 1,2 = 0
* bit 0 = 1
这样 OS不能再执行`VMXON` 开启VMX operation

> [!PDF|important] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3926&selection=57,0,64,2&color=important|325462-sdm-vol-1-2abcd-3abcd-4, p.3926]]
> > Before executing VMXON, software should allocate a naturally aligned 4-KByte region of memory that a logical processor may use to support VMX operation.1 This region is called the VMXON region. 
> 
> 需要分配一个`4-KByte` region

> [!PDF|note] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3926&selection=92,0,93,34&color=note|325462-sdm-vol-1-2abcd-3abcd-4, p.3926]]
> > Future processors may require that a different amount of memory be reserved. If so, this fact is reported to software using the VMX capability-reporting mechanism
> 
> 可能`VMXON region` 大小可能要改

## 24.8 RESTRICTIONS ON VMX OPERATION

> [!PDF|important] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3926&selection=78,13,80,10&color=important|325462-sdm-vol-1-2abcd-3abcd-4, p.3926]]
> > Any attempt to set one of these bits to an unsupported value while in VMX operation (including VMX root operation) using any of the CLTS, LMSW, or MOV CR instructions causes a general-protection exception.
> 
> 一旦执行了`VMXON`, 再执行某些指令操作`CR4, CR0`的VME相关控制位为unsupport value。(例如CR4.VMXE->0)， 会造成 `#GP`。

[[APPENDIX A VMX CAPABILITY REPORTING FACILITY]] 有详细描述

> [!PDF|important] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3927&selection=5,76,6,73&color=important|325462-sdm-vol-1-2abcd-3abcd-4, p.3927]]
> >  Therefore, guest software cannot be run in unpaged protected mode or in real-address mode.
> 
> 这个影响还是很大的，因为系统运行的BIOS 入口是实模式代码。


> [!PDF|important] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3927&selection=7,0,8,74&color=important|325462-sdm-vol-1-2abcd-3abcd-4, p.3927]]
> > Later processors support a VM-execution control called “unrestricted guest” (see Section 25.6.2). If this control is 1, CR0.PE and CR0.PG may be 0 in VMX non-root operation
> 
> 后来的处理器支持了 `“unrestricted guest”`的特性, 允许 `CR0.PE, CR0.PG` 允许在`VMX non-root operation`下设置为0

> [!PDF|todo] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3927&selection=17,0,17,50&color=todo|325462-sdm-vol-1-2abcd-3abcd-4, p.3927]]
> > VMXON fails if a logical processor is in A20M mode
> 
> A20M mode TODO

> [!PDF|important] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3927&selection=23,0,24,93&color=important|325462-sdm-vol-1-2abcd-3abcd-4, p.3927]]
> > The INIT signal is blocked whenever a logical processor is in VMX root operation. It is not blocked in VMX nonroot operation. Instead, INITs cause VM exits (see Section 26.2, “Other Causes of VM Exits”).
>  Oh MY leideigaga, 居然还有这种限制。WHY??

> [!PDF|todo] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3927&selection=28,0,32,15&color=todo|325462-sdm-vol-1-2abcd-3abcd-4, p.3927]]
> > Intel® Processor Trace (Intel PT) can be used in VMX operation only if IA32_VMX_MISC[14] is read as 1 (see Appendix A.6). 
> 
> PT TODO

单词翻译:

> [!PDF|translate] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3926&selection=80,101,80,108&color=translate|325462-sdm-vol-1-2abcd-3abcd-4, p.3926]]
> > consult
> 
> 咨询
