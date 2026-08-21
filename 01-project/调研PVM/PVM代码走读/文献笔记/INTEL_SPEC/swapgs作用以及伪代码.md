> [!PDF|] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=1898&selection=10,0,11,23|📖 swapgs 指令作用 -- 和 MSR IA32_KERNEL_GS_BASE exchange]]
> > SWAPGS exchanges the current GS base register value with the value contained in MSR address C0000102H (IA32_KERNEL_GS_BASE). 

> [!PDF|] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=1898&selection=25,0,42,27|📖 swapgs 指令伪代码]]
> > ```
> > Operation IF CS.L ≠ 1 (* Not in 64-Bit Mode *) 
> >   THEN #UD; 
> >   FI;
> > IF CPL ≠ 0 
> >   THEN #GP(0); 
> >   FI;
> >  ```
> CPL必须为0
> >  ```
> > tmp := GS.base;
> > GS.base := IA32_KERNEL_GS_BASE;
> > IA32_KERNEL_GS_BASE := tmp;
> > ``` 
> 	`GS.base <=> IA32_KERNEL_GS_BASE`
