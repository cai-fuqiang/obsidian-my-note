# A.7 VMX-FIXED BITS IN CR0


> [!PDF|note] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=4478&selection=24,16,25,96&color=note|325462-sdm-vol-1-2abcd-3abcd-4, p.4478]]
> > . If bit X is 1 in IA32_VMX_CR0_FIXED0, then that bit of CR0 is fixed to 1 in VMX operation. Similarly, if bit X is 0 in IA32_VMX_CR0_FIXED1, then that bit of CR0 is fixed to 0 in VMX operation
> 
> * IA32_VMX_CR0_FIXED0: 决定了CR0的那些bit必须固定设置为1(bit[i] = 1)
> * IA32_VMX_CR0_FIXED1: 决定了CR0的那些bit必须固定设置为0(bit[i] = 0)

> [!PDF|note] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=4478&selection=25,98,27,69&color=note|325462-sdm-vol-1-2abcd-3abcd-4, p.4478]]
> > It is always the case that, if bit X is 1 in IA32_VMX_CR0_FIXED0, then that bit is also 1 in IA32_VMX_CR0_FIXED1; if bit X is 0 in IA32_VMX_CR0_FIXED1, then that bit is also 0 in IA32_VMX_CR0_FIXED0. 
> 
> 根据上一句话，这是很明显的推论，如果
> * FIXED 0 如果某个bit为1，说明CR4该bit肯定设置为1，不能为0，所以FIXED1 也必须为1
> * FIXED 1  如果某个bit 为1,  说明CR4该bit肯定设置为0，不能设置为1，所以FIXED1 也必须为1

> [!PDF|important] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=4478&selection=27,70,29,20&color=important|325462-sdm-vol-1-2abcd-3abcd-4, p.4478]]
> > hus, each bit in CR0 is either fixed to 0 (with value 0 in both MSRs), fixed to 1 (1 in both MSRs), or flexible (0 in IA32_VMX_CR0_FIXED0 and 1 in IA32_VMX_CR0_FIXED1)
>  所以这里的结论是，要么多是0，要么都是1a

# A.8 VMX-FIXED BITS IN CR4

> [!PDF|important] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=4478&selection=31,0,33,21&color=important|325462-sdm-vol-1-2abcd-3abcd-4, p.4478]]
> > A.8 VMX-FIXED BITS IN CR4
> 
> 和上面的结论一样。不赘述。

单词翻译:
> [!PDF|translate] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=4478&selection=23,101,23,113&color=translate|325462-sdm-vol-1-2abcd-3abcd-4, p.4478]]
> > respectively
> 
> 分别

