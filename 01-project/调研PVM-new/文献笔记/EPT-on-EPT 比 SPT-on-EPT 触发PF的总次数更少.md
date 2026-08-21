对比下 EPT-on-EPT和 SPT-on-EPT 两者触发PF的时机, 以及触发对象的地址转换类型:

|            | 触发时机                    | 触发对象的地址转换类型                        |
| ---------- | ----------------------- | ---------------------------------- |
| EPT-on-EPT | update EPT<sub>12</sub> | GPA<sub>L2</sub>->GPA<sub>L1</sub> |
| SPT-on-SPT | update GPT<sub>L2</sub> | GVA<sub>L2</sub>->GPA<sub>L2</sub> |
是不是很熟悉 ?

这就是EPT和SPT的区别。EPT所表示的内存映射大部分场景下是固定的(GPA->HPA)(swap, ksm等等内存超卖的场景不固定)，所以对于某个地址区间触发PF往往是==一次性的==. 但是SPT不同，用户态程序会涉及频繁的内存申请和释放。这些==频繁改变其映射关系==。

所以，我们再次回到嵌套虚拟化中，**EPT-on-EPT需要监控 EPT<sub>12</sub>, 其本质上还是EPT，根据上面的结论, EPT本身==不容易变动==。而SPT-on-EPT 需要监控 GPT<sub>L2</sub>, 其和 single-level virt关注的对象一样! , 其会==频繁变动映射关系==**

```ad-note
我们这里将EPT volation ,和 `#PF` 统称为 `#PF`
```
