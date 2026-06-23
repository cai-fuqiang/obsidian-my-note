> [!PDF|important] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3210&selection=13,31,14,10&color=important|325462-sdm-vol-1-2abcd-3abcd-4, p.3210]]
> > If, however, the processor cannot handle them serially, it signals the double-fault exception.
>  什么是double-fault, 就是当不能串行处理每个异常的时候，就会触发double fault.
> NOTE:
> 串行触发不是指顺序处理 (one-by-one), 可就是说可以嵌套，但是能不能最终处理完这些异常。而不是变成无法恢复的状态。

> [!PDF|important] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3210&selection=16,104,17,106&color=important|325462-sdm-vol-1-2abcd-3abcd-4, p.3210]]
> >  A doublefault exception falls in the abort class of exceptions. The program or task cannot be restarted or resumed
> 
> 和上面的说法一样，无法恢复才是double fault的定义（而不是连续出发两个异常)


> [!PDF|note] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3211&selection=71,0,71,19&color=note|325462-sdm-vol-1-2abcd-3abcd-4, p.3211]]
> > Enter Shutdown Mode
> 
> 这个应该指的是tripple fault

> [!PDF|yellow] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3211&selection=8,0,9,32&color=yellow|325462-sdm-vol-1-2abcd-3abcd-4, p.3211]]
> > If another contributory or page fault exception occurs while attempting to call the double-fault handler, the processor enters shutdown mode. 
> 
> 进入shutdown mode 的条件(double-fault handler中，遇到 `another contributory` or `page fault`)

> [!PDF|note] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3211&selection=9,32,9,108&color=note|325462-sdm-vol-1-2abcd-3abcd-4, p.3211]]
> > This mode is similar to the state following execution of an HLT instruction.
> 
> 执行`hlt`指令会进入shoutdown state么? 不会，其会进入halt state。这里的意思是shutdown state 和 hlt 状态很像。

> [!PDF|yellow] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3211&selection=11,100,15,109&color=yellow|325462-sdm-vol-1-2abcd-3abcd-4, p.3211]]
> >  Software designers may need to be aware of the response of hardware when it goes into shutdown mode. For example, hardware may turn on an indicator light on the front panel, generate an NMI interrupt to record diagnostic information, invoke reset initialization, generate an INIT initialization, or generate an SMI. If any events are pending during shutdown, they will be handled after an wake event from shutdown is processed (for example, A20M# interrupts)
> 
> 这里说的是在软件设计者知道硬件如何响应 double fault 的.
> 但是这里有个疑问，double fault发生时，谁负责出发这些行为。还是说，double fault 有一个独立的上下文可以处理。
> 那肯定是有个独立上下文，double fault 是一个异常类型，其会走IDT.

> [!PDF|note] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3211&selection=10,48,11,9&color=note|325462-sdm-vol-1-2abcd-3abcd-4, p.3211]]
> >  until an NMI interrupt, SMI interrupt, hardware reset, or INIT# is received.
> 
> 注意这里没有`external interrupt`

> [!PDF|note] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3210&selection=17,108,19,85&color=note|325462-sdm-vol-1-2abcd-3abcd-4, p.3210]]
> > The double-fault handler can be used to collect diagnostic information about the state of the machine and/or, when possible, to shut the application and/or system down gracefully or restart the system
> 
>  这里提到的是double fault的意义. double fault 给了系统可以:
>  * 收集诊断信息
>  * 通过杀死用户态进程保证整个系统不被宕机
>  * 优雅关机或着重启

> [!PDF|todo] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3211&selection=5,0,6,19&color=todo|325462-sdm-vol-1-2abcd-3abcd-4, p.3211]]
> > A segment or page fault may be encountered while prefetching instructions; however, this behavior is outside the domain of Table 6-5
> 
> 还有这种行为么

> [!PDF|important] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3211&selection=16,0,17,22&color=important|325462-sdm-vol-1-2abcd-3abcd-4, p.3211]]
> > If a shutdown occurs while the processor is executing an NMI interrupt handler, then only a hardware reset can restart the processor.
> 
> 如果NMI中遇到了shutdown，只能重启了。

> [!PDF|important] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3211&selection=17,75,17,78&color=important|325462-sdm-vol-1-2abcd-3abcd-4, p.3211]]
> > SMM
> 
> SMM遇到shutdown 也只能重启

单词翻译:

> [!PDF|translate] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3210&selection=13,21,13,29&color=translate|325462-sdm-vol-1-2abcd-3abcd-4, p.3210]]
> > serially
> 
> 串行的

> [!PDF|translate] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3210&selection=15,26,15,33&color=translate|325462-sdm-vol-1-2abcd-3abcd-4, p.3210]]
> > benign 
> 
> 良性的

> [!PDF|translate] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3210&selection=15,45,15,57&color=translate|325462-sdm-vol-1-2abcd-3abcd-4, p.3210]]
> > contributory
> 
> 诱发性的

> [!PDF|translate] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3210&selection=18,44,18,54&color=translate|325462-sdm-vol-1-2abcd-3abcd-4, p.3210]]
> > diagnostic
> 
> 诊断

> [!PDF|translate] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3211&selection=17,23,17,31&color=translate|325462-sdm-vol-1-2abcd-3abcd-4, p.3211]]
> > Likewise
> 
> 同样的
