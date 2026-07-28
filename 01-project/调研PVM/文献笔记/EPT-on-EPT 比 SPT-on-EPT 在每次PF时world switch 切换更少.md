根据 [[sosp2023-pvm-paper.pdf]] 中的 world switch数量:

* EPT-on-EPT: $2(n+3)$
* SPT-on-EPT: $4(n+2)$

为什么会有两倍的关系呢?

原因在于, 两个场景，worldswitch大头部分都是 一阶段，一阶段的大部分工作是, fixup Page Table, 但是其触发异常的Lx 不同:

|            | fixup pagetable type   | Lx trigger exception |
| ---------- | ---------------------- | -------------------- |
| EPT-on-EPT | fixup EPT<sub>12</sub> | L1                   |
| SPT-on-EPT | fixup GPT<sub>2</sub>  | L2                   |

而 **L0做的是转发该异常**:
* EPT-on-EPT: 转发 EPT voliation to L1
* SPT-on-EPT: 转发 `#PF` to L2

那问题是L2 可以直接注入 EPT voliation 到 L1, 但是 L2 的异常注入的负责人是L1, 所以，其得让L1转发，但是L1准备完后，执行VMRESUME，会再次Trap 到L0，L0再做一些VMCS的模拟，由L0 执行VMRESUME 回L1

即:
* EPT-on-EPT: L1--触发ept voliation-->L0--转发ept voliation-->L1
* SPT-on-EPT: L2--触发PF-->L0--转发PF-->L1-->做一些模拟后，vmresume inst trap-->L0-- real vmresume--> L2