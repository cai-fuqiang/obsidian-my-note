

FROM: [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3926&offset=46,727,0|325462-sdm-vol-1-2abcd-3abcd-4, 24.7 Enabling and Entering VMX Operation]]

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
