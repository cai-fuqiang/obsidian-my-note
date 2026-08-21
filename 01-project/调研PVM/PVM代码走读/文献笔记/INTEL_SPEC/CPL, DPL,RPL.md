# CPL
> [!PDF|] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3150&selection=18,1,18,75|📖 CPL 是当前 executing program / task 的特权级 ]]
> >  The CPL is the privilege level of the **==currently== executing program or task**

> [!PDF|] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3150&selection=19,61,21,75|📖  CPL通常等同于要执行的代码段的特权级。 所以CPL 的改变往往是因为跳转到特权级不同的代码段]]
> >  Normally, the CPL is equal to the privilege level of the code segment from which instructions are being fetched. The processor changes the CPL when program control is transferred to a code segment with a different privilege level. 

> [!PDF|] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3150&selection=22,41,25,29|📖 TODO Conforming code segments/nonconforming code segment]] 
> > Conforming code segments can be accessed from any privilege level that is equal to or numerically greater (less privileged) than the DPL of the conforming code segment. Also, the CPL is not changed when the processor accesses a conforming code segment that has a different privilege level than the CPL.
# DPL
> [!PDF|] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3150&selection=31,1,33,23|📖 DPL 指的是一个segment/gate 的特权级]]
> >  The DPL is the privilege level of a segment or gate. 

> [!PDF|] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3150&selection=34,65,37,42|📖 当正在执行的代码段要访问一个segment/gate时， 会 比较 CPL和其要访问segment/gate的DPL]]
> > When the currently executing code segment attempts to access a segment or gate, the DPL of the segment or gate is compared to the CPL and RPL of the segment or gate selector (as described later in this section). The DPL is interpreted differently, depending on the type of segment or gate being accessed
> 

> [!PDF|] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3150&selection=36,63,37,42|📖 DPL的解释方式和其要访问的 segment/gate 的类型有关]]
> 
> *  **Data segment** : 表示允许程序或任务访问该段的 **==最高==特权级别**。(**数字越大，特权级别越低**)
> * **Nonconforming code segment (without using a call gate)**:  DPL == CPL(must)
> * **Call gate**: 和 `Data segment`相同
> * **Conforming code segment and nonconforming code segment accessed through a call gate** :
>    DPL 表示允许程序或任务访问该段的 **==最低==特权级别**。
# RPL

> [!PDF|] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3151&selection=16,2,17,11| 📖 RPL存储在 Segment Selector 中， 并用于特权级覆盖(CPL)]]
> > The RPL is an override privilege level that is assigned to segment selectors. 

> [!PDF|] [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3151&selection=18,47,20,112|📖 在实际访问时, 选用CPL和 RPL中较低的特权级进行访问]]
> >  Even if the program or task requesting access to a segment has sufficient privilege to access the segment, **access is ==denied== if the RPL is ==not== of sufficient privilege level**. That is, if the RPL of a segment selector is numerically **greater** than the CPL, the RPL **overrides** the CPL, and **vice versa**.