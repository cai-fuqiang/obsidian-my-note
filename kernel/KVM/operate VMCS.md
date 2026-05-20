Intel 手册在下面的章节中描述了使用VMCS的一些方法和限制:
[[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3956&offset=46,350,0|325462-sdm-vol-1-2abcd-3abcd-4, 25.11 Software Use of the VMCS and Related Structures]]

## 初始化
[[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3959&offset=45,680,0| 相关章节]]

> [!PDF|important] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3959&selection=12,96,14,81&color=important|325462-sdm-vol-1-2abcd-3abcd-4, p.3959]]
> > Failure to do so may result in unpredictable behavior; for example, a VM entry may fail for unexplained reasons, or a successful transition (VM entry or VM exit) may load processor state with unexpected values.
> 
> 在使用VMCS之前应该进行初始化，否则可能产生一些未知的行为