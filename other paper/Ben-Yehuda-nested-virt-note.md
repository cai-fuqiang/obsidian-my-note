# 3.2 CPU: Nested VMX Virtualization

> [!PDF|yellow] [[Ben-Yehuda-nested-virt.pdf#page=4&selection=43,0,43,12&color=yellow|Ben-Yehuda-nested-virt, p.4]]
> > Virtualizing
> 
> 这段讲述了较老的x86架构（无硬件虚拟化）虚拟化模拟性能低下的现状
> 

> [!PDF|yellow] [[Ben-Yehuda-nested-virt.pdf#page=4&selection=51,0,51,2&color=yellow|Ben-Yehuda-nested-virt, p.4]]
> > In
> 
> 这段描述了Intel 和 AMD 引入的硬件虚拟化基本架构
> 模式分为:
> * virtual machine(guest mode)
> * hypervisor(root mode)
> 引入`VMCS`, `VMCB`作用是:
> ```
>  contain environment specifications for virtual machines and the hypervisor.
> ```

> [!PDF|yellow] [[Ben-Yehuda-nested-virt.pdf#page=4&selection=75,0,75,7&color=yellow|Ben-Yehuda-nested-virt, p.4]]
> > The VMX
> 
> 这段描述了, VMCS的格式分为三大块:
> * guest state
> * host state
> * Control data

> [!PDF|yellow] [[Ben-Yehuda-nested-virt.pdf#page=4&selection=98,0,98,9&color=yellow|Ben-Yehuda-nested-virt, p.4]]
> > In nested
> 
> 嵌套虚拟化基本架构分层:
> L0: root mode
> L1: guest mode but is guest os hypervisor
> L2: virtual machine create by L1

> [!PDF|yellow] [[Ben-Yehuda-nested-virt.pdf#page=4&selection=114,0,114,6&color=yellow|Ben-Yehuda-nested-virt, p.4]]
> > As can
> 
> 这段话详细描述了基于VMX嵌套虚拟化基本实现:
> 有三种VMCS:
> * VMCS<sub>0-1</sub>: 用于L<sub>0</sub> <--> L<sub>1</sub>
> * VMCS<sub>1-2</sub>: 用于L<sub>1</sub> <--> L<sub>2</sub>
> * VMCS<sub>0-2</sub>: 用于L<sub>0</sub> <--> L<sub>2</sub>
>
> 其中VMCS<sub>1-2</sub>不会load到CPU中(文章中是这么说的，但是Intel sdm中有提到，这个VMCS 也是active的,文章中的意思是不会变为current VMCS, 或者暂不考虑VMCS shadow)


单词翻译 :

> [!PDF|translate] [[Ben-Yehuda-nested-virt.pdf#page=4&selection=47,7,47,18&color=translate|Ben-Yehuda-nested-virt, p.4]]
> >  on-the-fly 
> 
> 即时

> [!PDF|translate] [[Ben-Yehuda-nested-virt.pdf#page=4&selection=50,7,50,18&color=translate|Ben-Yehuda-nested-virt, p.4]]
> > compilation
> 
> 汇编

> [!PDF|translate] [[Ben-Yehuda-nested-virt.pdf#page=4&selection=117,19,118,9&color=translate|Ben-Yehuda-nested-virt, p.4]]
> > multiplexing
> 
> 多路复用

> [!PDF|translate] [[Ben-Yehuda-nested-virt.pdf#page=4&selection=136,25,137,10&color=translate|Ben-Yehuda-nested-virt, p.4]]
> >  Respectively
> 
> 分别

## 3.2.1 VMX Trap and Emulate

> [!PDF|yellow] [[Ben-Yehuda-nested-virt.pdf#page=4&selection=183,0,184,1&color=yellow|Ben-Yehuda-nested-virt, p.4]]
> > 3.2.1
> 
> 整段描述了如何去 emulate VMX instructions.

> [!PDF|yellow] [[Ben-Yehuda-nested-virt.pdf#page=4&selection=187,0,187,3&color=yellow|Ben-Yehuda-nested-virt, p.4]]
> > VMX
> 
> 首先VMX instruction(部分) **只能** 在root mode中执行成功。
> 在L1 中会VMEXITS。从而让L0来模拟L1执行的这些指令

> [!PDF|yellow] [[Ben-Yehuda-nested-virt.pdf#page=4&selection=202,0,202,10&color=yellow|Ben-Yehuda-nested-virt, p.4]]
> > In general
> 
> 这一段描述的是虚拟机执行类似于`VMWRITE`的操作, 需要trap到L0模拟，所以整个过程是:
> 1. L1 execute VMX instruction
> 2. L1 VMEXIT to L0
> 3. L0 emulate VMX instruction
> 4. L0 emulated, then VMentry to L1
> 
> 但是本段并未描述模拟细节。

> [!PDF|yellow] [[Ben-Yehuda-nested-virt.pdf#page=4&selection=235,0,235,3&color=yellow|Ben-Yehuda-nested-virt, p.4]]
> > For
> 
> 本节描述了如何去 run a new vm.  正常来说VMM负责执行`VMLANCH`, `VMRESUME`来切换到guest mode。但是在嵌套虚拟化中要复杂. 因为L1执行`VMLANCH(RESUME)`时，就会vmexit。而L1期望执行完这条指令后，就会进入L2（如果check pass)。另外L0也希望，或者要求去模拟VMLANCH(RESUME)指令。所以整个流程如下:
> * L1 execute VMLANCH
> * L1 VMexit to L0
> * L0 emulate VMLANCH
> * L0 VMENTRY TO `LLLLLL2222222`
> 所以最终需要L0直接进入L2



> [!PDF|translate] [[Ben-Yehuda-nested-virt.pdf#page=4&selection=302,2,302,9&color=translate|Ben-Yehuda-nested-virt, p.4]]
> > exactly
> 
> 确切的

> [!PDF|translate] [[Ben-Yehuda-nested-virt.pdf#page=4&selection=304,45,304,56&color=translate|Ben-Yehuda-nested-virt, p.4]]
> > perspective
> 
> 视角, 看法


## 3.2.2 VMCS Shadowing

> [!PDF|important] [[Ben-Yehuda-nested-virt.pdf#page=4&selection=284,0,286,14&color=important|Ben-Yehuda-nested-virt, p.4]]
> > 3.2.2 VMCS Shadowing
> 
> 整段在描述VMM如何使用VMCS来控制/切换L2的。
> 在看整个段落之前, 我们首先思考:
> * 虚拟化作用？
>    * 虚拟化是指让某些软件看起来像是运行在一套完整的硬件上。但实际上不是，该硬件会被host os，vmm以及其他vm共享。
> * 虚拟化的方法论是什么？
> 	* 像`<<操作系统导论>>`讲解调度一样，将调度子系统归结为虚拟化。虚拟化实际上就是对资源的分时/分区复用
> * 虚拟化的手段是什么？
> 	* 虚拟化的手段是trap && emulate。当VM执行特权指令访问关键（共享）资源时(当然不只是特权指令会触发trap), trap到VMM, 由VMM来emulate 该指令，为该分配指令所需的资源.
> * 那问题来了? L2的 emulate 由谁 管理？
> 	* 首先我们需要明确，emulate 是为了干啥。为了划分共享资源。那谁管理着共享资源? 
>        **L0**!
>        所以, L0 需要模拟L0,L1 的VM-exit。
>    * 模拟的一个重要媒介是啥？
>       * VMCS, 准确说应该是VMCS<sub>0->2</sub>
>    好这就是整个章节的重点内容:
> <font color="red">如何在L0为L2准备VMCS<sub>0-2</sub></font>


> [!PDF|yellow] [[Ben-Yehuda-nested-virt.pdf#page=4&selection=288,0,290,1&color=yellow|Ben-Yehuda-nested-virt, p.4]]
> > L0
> 
> L0准备L1 的VMCS(vmcs<sub>0->1</sub>), 这个就像没有嵌套虚拟化，VMM为VM准备VMCS一样。
> 但是L1认为自己运行在物理机(root mode), 会执行VMX 指令来管理自己的guest(L2)

> [!PDF|yellow] [[Ben-Yehuda-nested-virt.pdf#page=4&selection=318,0,321,5&color=yellow|Ben-Yehuda-nested-virt, p.4]]
> > L1 define
> 
> 本段描述了 不同层VMM(L1 && L0) 的视角下需要不同VMCS的原因。
> L1 给L2分配的VMCS是在L1的视角下分配。而在L1视角下，分配给L2的资源是虚拟的不是真正的物理资源。所以起不能作为current VMCS给 CPU使用。这时候需要真正的物理资源支配者L0, 搞出其视角下分配给L2的VMCS。

> [!PDF|yellow] [[Ben-Yehuda-nested-virt.pdf#page=5&selection=20,0,24,1&color=yellow|Ben-Yehuda-nested-virt, p.5]]
> > L0 must 
> 
> 本段描述了L0构建VMCS0-2的注意事项。以及如何构建部分字段，总结如下:
> * L0 应该考虑 VMCS1->2 中的 specifications的同时也应该考虑VMCS0->1的specification
> * L0构造VMCS0->2时，应该如下填充字段:
> 	* host state: 应该填充L0的相关信息，以便L2 vmexit时，能正确跳转回L0
> * L0构造VMCS1->2时:
> 	* guest state: 从 VMCS1->2 的host state中获取

> [!PDF|yellow] [[Ben-Yehuda-nested-virt.pdf#page=5&selection=107,0,107,15&color=yellow|Ben-Yehuda-nested-virt, p.5]]
> > The guest state
> 
> 本段描述了L0填充VMCS0->2的guest state字段。
> 应该直接从VMCS1->2不需要做任何处理，直接copy到VMCS0->2 guest state

> [!PDF|yellow] [[Ben-Yehuda-nested-virt.pdf#page=5&selection=123,0,123,17&color=yellow|Ben-Yehuda-nested-virt, p.5]]
> > The control data 
> 
> 本段描述了control data该如何填充。

单词翻译:

> [!PDF|translate] [[Ben-Yehuda-nested-virt.pdf#page=5&selection=5,3,5,12&color=translate|Ben-Yehuda-nested-virt, p.5]]
> > construct
> 
> 构造

