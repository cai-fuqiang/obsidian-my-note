---
created: 2026-09-17T09:30:35+08:00
modified: 2026-09-17T10:51:47+08:00
share_link: https://share.note.sx/4meklea4#Q4XArc0yE1g2VbUqY9/Bvg
share_updated: 2026-09-17T10:51:37+08:00
---
# PVM 概述
PVM 是蚂蚁开发的基于KVM API的半虚拟化加速器，用于在没有VMX feature的情况下创建虚拟机，常用来替代嵌套虚拟化场景，可以在L0 不开启嵌套虚拟化feature的情况下，创建L2 虚拟机，以避免嵌套虚拟化所带来的安全性问题。

另外在嵌套虚拟化场景下，world switch的代价过高，L2 无法直接会回退L1,  需要L0转发，这样每次L0 -- L1 之间的每次world switch都需要经历两次昂贵的vm-exit。而PVM提供了半虚拟化方法，编写简单高效的switcher代码，可以让L2 直接回退L1，并且切换效率很高。

在嵌套虚拟化场景下(特定场景)，page fault所带来的损耗较大，PVM针对该方面做了一些优化，尤其是并行方面。

我这边的主要工作是，了解PVM原理，并针对论文提到的测试场景进行复测。

# PVM 测试结果
## micro-test

![[06b-测试world switch#^76e8c3]]

嵌套虚拟化场景下, `PVM` 的world switch性能确实要比`kvm` 强不少。但是可能是因为`L1` 本身的损耗导致, `PVM`在嵌套虚拟化下，比`PVM`在裸金属下(单极虚拟化) 性能要低一倍左右。
## syscall

![[06c-测试syscall#^88d1fd]]

无论是基于KVM的嵌套虚拟化还是基于KVM的单极虚拟化，`syscall` 指令本身不会`vm-exit`。而`PVM` 在`syscall`时需要额外的上下文切换，很类似于 裸金属中的 `KPTI`场景。所以PVM在简单 `syscall`(例如`getgpid()` ) 的性能和`KVM` 开启KPTI 类似。

> [!error] 但是需要注意的是，`PVM`在`fork`, `execve` 场景性能极低。原因是，这个测试中，只会申请内存，但是不会访问。`PVM`其会频繁的修改 `GPT` 而触发`WP pagefault`， 而 `KVM` 则不会。

## pagefault

> [!quote] 细节请参考 [[06c01-PVM-PF-PERF-README]] 

本来以为`PVM`在`pagefault`层面会比嵌套虚拟化优秀很多。但是，经过调试+走读代码发现

> [!summary] PVM 内存虚拟化本身基于影子页表做优化，其具有和影子页表相同的缺陷。所以，其性能提升只针对于==特定场景==。

> [!danger]  PVM的优势点只在于L2 冷虚拟机。当KVM 嵌套虚拟机完全预热后，EPT<sub>02</sub> 建立充分，L2不再触发 `EPT voliation` event。但是如果是冷启动，KVM 嵌套虚拟机会频繁处理 `EPT voliation`，而又因为 world switch 性能差，从而导致性能落后于PVM。

> [!danger] 而如果L2充分预热后，PVM 会因解除内存映射，频繁创建销毁进程等等原因, 而重建/invalid 影子页表，而造成额外的pagefault, 导致其性能远远落后于KVM。

总结如下:

PVM适合:
* L2 启动
* 应用不会频繁创建，解除映射。不会频繁起停进程

KVM 适合:
* 不关注启动和预热速度
* 长时间运行的程序

> [!todo] 而针对`PVM`适合的场景，其中之一是基于kata的安全容器启动。

# system bench
我们使用了`lmbench` 做了如下测试:

![[06e-测试lmbench#^00c9d5]]

`PVM`在 很多指标上性能优于`kvm`。但是后面的三项测试，仍然受限于影子页表缺陷，而导致性能远远落后嵌套虚拟化。

# real world app
`real world app` 做的测试优先， 主要是测试如下几个方面:

## 安全容器启动

冷启动
![[06a-测试安全容器启动#^0ad6ff]]

快照启动

![[06a-测试安全容器启动#^d72564]]

> [!summary] **`PVM` 在冷启动和快照启动方面性能均==比嵌套虚拟化优秀==，但是性能落后于 ==单极虚拟化==**

> [!todo] 我这边预测，在多实例方面，`PVM`因为`kvm mmu-lock`的锁粒度更小，比嵌套虚拟化比有更大的提升。但是目前还未测试。

## 网络服务

这里不再展开，简单来说，网络服务方面，PVM性能几乎都比 嵌套虚拟化低(redis 几乎持平，netperf 某些指标性能高一些），[[06f-测试 real world app]]。

## 复测论文app

论文中提到了几个app，但是受限于不了解其压测方式，测试结果也没有体现出全面优势:

详细参考: [[06f01-测试real world app -paper]]

> [!todo] [ ] 还需要再做进一步测试

# 结论
*  `PVM`的优势在于`world switch` 性能好，但是其page fault数量，可能会比较多。而嵌套虚拟化的优势在于 page fault 数量肯定比`PVM`少，在某些场景下，数量要少不止一个量级，但是`world switch` 性能差。
> [!summary]  两者性能差距，本质上是`world switch` 性能和 `page fault` 次数的综合差距。

* `PVM` 目前测试看，其性能优势仅体现在L2 虚拟机还未预热的场景下，所以在安全容器启动这个场景下, PVM对比嵌套虚拟化有着不错的优势(多实例推测优势更大，需要进一步测试）。但是和单极虚拟化相比，其性能还是差不少。(这个可能能再继续调优)。

所以，如果没有强烈的将安全容器底座，迁移到虚拟机，建议还是使用裸金属方式。目前的PVM方案仍有较大的优化空间。

# 未来展望

能不能把`PVM` 的优势和嵌套虚拟化的优势结合起来呢? 

可以！蚂蚁今年下半年，新发布了 [JANUS](https://github.com/virt-pvm/misc/blob/main/osdi2026-janus-paper.pdf)。其仍然保持PVM CPU 虚拟化的方式，但是在内存虚拟化方面，使用类似于嵌套虚拟化的 **GPT+ EPT<sub>02</sub>** ,彻底废弃了影子页表！L1不在track GPT, 这也就意味着影子页表的缺点不再存在! 并且使用 `VMFUNC` + `#VE` 的硬件虚拟化技术。避免
* 切换 EPT<sub>01</sub>, EPT<sub>02</sub> 时，trap L0
* 触发 EPT violation是，直接trap L1, 而不是L0, 避免掉一次VM exit

经过上面的优化，其在 L2 触发 ept violation 时，只需要进行一次 昂贵的 VM exit VM-entry。和单极虚拟化类似！

> [!success] **这看起来像是嵌套虚拟化的==终极方案==**。但是**该方案目前==并未开源==**。


# TODO
* [ ] 测试安全容器的多实例启动
* [ ] 继续走读 JANUS 论文，了解 JANUS原理