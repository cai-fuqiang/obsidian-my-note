# 25.1 OVERVIEW
> [!PDF|note] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3928&selection=16,33,18,27&color=note|325462-sdm-vol-1-2abcd-3abcd-4, p.3928]]
> > hese manage transitions into and out of VMX non-root operation (VM entries and VM exits) as well as processor behavior in VMX non-root operation. 
> 
> 上一个章节也提到过VMCS的两个功能，不赘述。

> [!PDF|note] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3928&selection=20,0,21,101&color=note|325462-sdm-vol-1-2abcd-3abcd-4, p.3928]]
> > A VMM can use a different VMCS for each virtual machine that it supports. For a virtual machine with multiple logical processors (virtual processors), the VMM can use a different VMCS for each virtual processor.
> 
> 上一个章节也提到过

> [!PDF|note] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3928&selection=22,0,36,3&color=note|325462-sdm-vol-1-2abcd-3abcd-4, p.3928]]
> > A logical processor associates a region in memory with each VMCS. This region is called the VMCS region. 1 Software references a specific VMCS using the 64-bit physical address of the region (a VMCS pointer). VMCS pointers must be aligned on a 4-KByte boundary (bits 11:0 must be zero). These pointers must not set bits beyond the processor’s physical-address width.2,3
> 
> 上一个章节也提到过

> [!PDF|translate] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3928&selection=37,0,46,6&color=translate|325462-sdm-vol-1-2abcd-3abcd-4, p.3928]]
> > A logical processor may maintain a number of VMCSs that are active. The processor may optimize VMX operation by maintaining the state of an active VMCS in memory, on the processor, or both. At any given time, at most one of the active VMCSs is the current VMCS. 
> 
> 每个处理器都会有 "一些 " active的 VMCS。处理器会做一些优化策略，通过在 memory, processor or both 维护 active VMCS 的状态。在任意时刻，最多只有一个active vmcs为current vmcs.

> [!PDF|translate] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3928&selection=59,0,61,81&color=translate|325462-sdm-vol-1-2abcd-3abcd-4, p.3928]]
> > The VMCS link pointer field in the current VMCS (see Section 25.4.2) is itself the address of a VMCS. If VM entry is performed successfully with the 1-setting of the “VMCS shadowing” VM-execution control, the VMCS referenced by the VMCS link pointer field becomes active on the logical processor
> 
> `VMCS link pointer` 也指一个VMCS, 而其VMCS 为current VMCS , 并且"VMCS shadowing" 字段为1，则会将该`vmcs`变换为`active VMCS`。

> [!PDF|important] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3928&selection=61,83,62,20&color=important|325462-sdm-vol-1-2abcd-3abcd-4, p.3928]]
> > The identity of the current VMCS does not change
> 
> 这句话是非常重要的，current VMCS在这个过程中不会变!
> 这里需要结合嵌套虚拟化知识了:
> [[Ben-Yehuda-nested-virt-note]]
> 控制guest行为, 是通过`current VMCS`。而在嵌套虚拟化的情况下, current VMCS应该控制L1, L2两者的行为。
> * VMCS_0_2: 在L0视角控制L1, L2
> * VMCS_1_2: 在L1视角用之L2
> * VMCS_0_1: 在L0视角控制L1
> 
> 所以在L0 enter L2 时，应该用current VMCS控制L1,L2 所以应使用vmcs_0_2,  而 VMCS link pointer 指向的是vmcs_1_2。用来L1 加速 vmx 指令的执行。这也是将其变为active的目的，变为active就意味着有部分数据从内存load到cpu中，可以做到加速。

> [!PDF|yellow] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3928&selection=71,0,75,79&color=yellow|325462-sdm-vol-1-2abcd-3abcd-4, p.3928]]
> > The launch state of a VMCS determines which VM-entry instruction should be used with that VMCS: 
> 
> `lanch state`决定了 `vm-entry`时，使用哪个指令:
> *  not lanch: VMLANCH
> * lanched: VMRESUME

> [!PDF|note] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3928&selection=77,33,78,7&color=note|325462-sdm-vol-1-2abcd-3abcd-4, p.3928]]
> >  A logical processor maintains a VMCS’s launch state in the corresponding VMCS region.
> 
> 在`VMCS region`中维护的 lanch state。而不是在VMX region中。

> [!PDF|note] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3928&selection=92,0,93,64&color=note|325462-sdm-vol-1-2abcd-3abcd-4, p.3928]]
> > There are no other ways to modify the launch state of a VMCS (it cannot be modified using VMWRITE) and there is no direct way to discover it (it cannot be read using VMREAD)
> 
> 虽然其在VMCS region中，但是Intel 并未提供任何指令可以读取, 写入该字段。（这也体现了VMCS的优势, 通过VMX instruction， 暴露用户需要的API。而隐藏元数据部分)


> [!PDF|translate] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3929&selection=10,51,11,116&color=translate|325462-sdm-vol-1-2abcd-3abcd-4, p.3929]]
> > Note that VMCLEAR X makes X “inactive, not current, and clear,” even if X’s current state is not defined (e.g., even if X has not yet been initialized). See Section 25.11.3
> 
> 即使X `current state`是 undefine 的状态，其也会将状态变为`[inactive, not current, clear]` 状态.

> [!PDF|note] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3929&selection=12,0,13,15&color=note|325462-sdm-vol-1-2abcd-3abcd-4, p.3929]]
> > Because a shadow VMCS (see Section 25.10) cannot be used for VM entry, the launch state of a shadow VMCS is not meaningful.
> 
> shadow VMCS不会被用作VM entry.

单词翻译:

> [!PDF|translate] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3928&selection=61,87,61,95&color=translate|325462-sdm-vol-1-2abcd-3abcd-4, p.3928]]
> > identity
> 身份

# 25.2 FORMAT OF THE VMCS REGION

> [!PDF|important] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3929&selection=30,0,36,19&color=important|325462-sdm-vol-1-2abcd-3abcd-4, p.3929]]
> > 0 Bits 30:0: VMCS revision identifier Bit 31: shadow-VMCS indicator (see Section 25.10) 4 VMX-abort indicator
> 
> 这些字段访问不用特殊的VMX instruction(`VMREAD/VMWRITE`)

> [!PDF|note] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3929&selection=42,0,43,32&color=note|325462-sdm-vol-1-2abcd-3abcd-4, p.3929]]
> > The exact size is implementation specific and can be determined by consulting the VMX capability MSR IA32_VMX_BASIC to determine the size of the VMCS region
> 
> 最多4-Byte，实际通过`IA32_VMX_BASIC`指定

> [!PDF|translate] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3930&selection=18,0,19,86&color=translate|325462-sdm-vol-1-2abcd-3abcd-4, p.3930]]
> > Bit 31 of this 4-byte region indicates whether the VMCS is a shadow VMCS (see Section 25.10).
> 
> bit 31 有特殊用途, 用作只是该VMCS是否用作shadow VMCS

> [!PDF|translate] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3930&selection=20,0,20,105&color=translate|325462-sdm-vol-1-2abcd-3abcd-4, p.3930]]
> > Software should write the VMCS revision identifier to the VMCS region before using that region for a VMCS
> 
> 软件负责写这个字段，`VMPTRLD`会去读这个字段，并且判断软件填写的值，是否和硬件本身的值相同。如果不相同则vm-fail

> [!PDF|translate] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3930&selection=24,16,27,17&color=translate|325462-sdm-vol-1-2abcd-3abcd-4, p.3930]]
> > Software can discover the VMCS revision identifier that a processor uses by reading the VMX capability MSR IA32_VMX_BASIC (see Appendix A.1
> 
> 软件可以通过`IA32_VM_BASIC`获取到硬件所使用的值

> [!PDF|yellow] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3930&selection=28,0,28,16&color=yellow|325462-sdm-vol-1-2abcd-3abcd-4, p.3930]]
> > Software should 
> 
> 这段讲软件怎么操作 shadow-VMCS indicator字段.

> [!PDF|yellow] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3930&selection=32,0,32,16&color=yellow|325462-sdm-vol-1-2abcd-3abcd-4, p.3930]]
> > The next 4 bytes
> 
> 这段讲`VMX-abort indicator`, 该字段不是一个控制字段。而是当VMX abort 发生时，处理器填入一个值，用于指示VMX abort reason(是一个information字段)

> [!PDF|important] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3930&selection=44,38,45,96&color=important|325462-sdm-vol-1-2abcd-3abcd-4, p.3930]]
> > To ensure proper behavior in VMX operation, software should maintain the VMCS region and related structures (enumerated in Section 25.11.4) in writeback cacheable memory
> 
> 要使用writeback cache memory

单词翻译:
> [!PDF|translate] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3929&selection=19,14,19,23&color=translate|325462-sdm-vol-1-2abcd-3abcd-4, p.3929]]
> > comprises
> 
> 包括.

> [!PDF|translate] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3930&selection=48,18,48,25&color=translate|325462-sdm-vol-1-2abcd-3abcd-4, p.3930]]
> > consult
> 
> 咨询


# 25.4 GUEST-STATE AREA
## 25.4.1 Guest Register State

> [!PDF|important] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3931&selection=29,0,29,20&color=important|325462-sdm-vol-1-2abcd-3abcd-4, p.3931]]
> > RSP, RIP, and RFLAGS
> 
> 注意没有`RAX`, `RBX`等通用寄存器。这些需要软件自己切换

> [!PDF|important] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3932&selection=28,0,28,19&color=important|325462-sdm-vol-1-2abcd-3abcd-4, p.3932]]
> > The following MSRs:
> 
> 这些MSR直接在VMCS中


单词翻译:
> [!PDF|translate] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3930&selection=97,3,97,15&color=translate|325462-sdm-vol-1-2abcd-3abcd-4, p.3930]]
> > collectively
> 
> 集体


## 25.4.2 Guest Non-Register State

> [!PDF|important] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3933&selection=29,0,31,11&color=important|325462-sdm-vol-1-2abcd-3abcd-4, p.3933]]
> > Activity state (32 bits). 
> 
> Active State 用来存储 vcpu 在vm-exit之前的 cpu state; 如果要是进入了 inactive state, 需要特殊的event才能唤醒该cpu，让其继续执行


单词翻译:
> [!PDF|translate] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3933&selection=25,0,25,12&color=translate|325462-sdm-vol-1-2abcd-3abcd-4, p.3933]]
> > characterize
> 
> 描述
