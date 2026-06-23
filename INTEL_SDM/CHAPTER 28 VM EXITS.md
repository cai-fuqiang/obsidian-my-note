# 28.1 ARCHITECTURAL STATE BEFORE A VM EXIT
> [!PDF|translate] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=4015&selection=32,0,32,101&color=translate|325462-sdm-vol-1-2abcd-3abcd-4, p.4015]]
> > If the logical processor is in an inactive state (see Section 25.4.2) and not executing instructions,
> 
> 如果处理器进入了inactive state, 其将不会执行任何指令

> [!PDF|important] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=4015&selection=32,102,33,85&color=important|325462-sdm-vol-1-2abcd-3abcd-4, p.4015]]
> > some events may be blocked but others may return the logical processor to the active state
> 
> 有两种事件:
> * blocked event: 这些事件将被屏蔽
> * unblocked event: 这些事件将处理器拉回active state

> [!PDF|translate] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=4015&selection=33,87,41,1&color=translate|325462-sdm-vol-1-2abcd-3abcd-4, p.4015]]
> > Unblocked events may cause VM exits. 2 If an unblocked event causes a VM exit directly, a return to the active state occurs only after the VM exit completes.3
> 
> 怎么拉回呢？就是产生vm-exit。而在vm-exit complete 之前，处理器是"真的"处于inactive state，在vm-exit complete之后，从inactive state 切回 active state。

> [!PDF|note] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=4015&selection=42,1,43,58&color=note|325462-sdm-vol-1-2abcd-3abcd-4, p.4015]]
> > he VM exit generates any special bus cycle that is normally generated when the active state is entered from that activity state.
> 
> 为什么说是真的呢？ 因为在VM-exit时，会产生一个特殊的bus cycle，这个bus cycles跟在物理环境上从inactive state 切换回 active state行为一样。
> 这句话里的activity state 个人认为指的是inactive state


[deepseek 解释](https://chat.deepseek.com/share/ql6xuh8xunftg0trdb)

> [!PDF|translate] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=4014&selection=84,14,84,21&color=translate|325462-sdm-vol-1-2abcd-3abcd-4, p.4014]]
> > bullets
> 
> 要点

## 28.3.4 Saving Non-Register State

> [!PDF|important] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=4039&selection=7,0,10,16&color=important|325462-sdm-vol-1-2abcd-3abcd-4, p.4039]]
> > The activity-state field is saved with the logical processor’s activity state before the VM exit.1 
> 
> 在VM exit之前，处理器会将logical processor's activity state 保存到VMCS的active state field中

> [!PDF|todo] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=4039&selection=11,79,13,84&color=todo|325462-sdm-vol-1-2abcd-3abcd-4, p.4039]]
> > f the VM exit occurred during userinterrupt notification processing (see Section 7.5.2) and the logical processor would have entered the HLT state following user-interrupt notification processing, the saved activity state is “HLT”.
> 
> user interrupt 相关