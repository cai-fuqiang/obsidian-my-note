# Direct Calls or Jumps to Code Segments

> [!PDF|] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3154&selection=25,0,26,25|📖 direct call/jump to code seg, CPL 必须等同于目标代码段的 DPL]]
> > When accessing nonconforming code segments, the CPL of the calling procedure must be equal to the DPL of the destination code segment;
> 

> [!PDF|] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3155&selection=32,50,33,42|📖 访问 conforming code segment 是唯一能让 DPL 不同于 CPL 的情形]]
> >  This situation is the only one where the CPL may be different from the DPL of the current code segment. 

> [!PDF|] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3155&selection=25,0,27,54|📖 对于 conforming code segment, DPL表示访问该段低的特权级]]
> > For conforming code segments, **the DPL represents the numerically ==lowest== privilege level that a calling procedure** may be at to successfully make a call to the code segment.
> 

> [!PDF|] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3155&selection=34,0,37,8|📖 一致性代码段常用作 不需要访问需要保护的系统资源，而是操作系统或者executive software提供的公共库(e.g.math), 或者异常处理程序]]
> > Conforming segments are used for code modules such as math libraries and exception handlers, which support applications but do not require access to protected system facilities. These modules are part of the operating system or executive software, but they can be executed at numerically higher privilege levels (less privileged levels).
> 
