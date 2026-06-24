# 简述

关于虚拟化的整体框架的设计不过多描述，虚拟机有些特权指令会通过HOST侧模拟完成。

![[Excalidraw/virt_overflow.excalidraw]]

而host侧模拟往往有两个角色配合完成
* kernel space:  KVM
* user space: QEMU

KVM一般完成，CPU支持的硬件虚拟化的功能。以及完成一些事件的加速（qemu/kvm都可以做，但是在KVM中做会减少事件退出到用户态处理）。

所以, KVM侧的优化一般有两种方式:
* 减少VM-exit
* 减少KVM->qemu 切换

KVM需要完成哪些主要职责呢?
* 进入，退出虚拟机(vm-entry, vm-exit)只能有KVM来接管。所以KVM是进入退出
  VM的入口
* 完成某些只能在kernel侧做的硬件虚拟化的配置, 例如:
	* 内存虚拟化: EPT
	* CPU虚拟化: 配置，管理VMCS
	* 中断虚拟化: 配置，管理vapic
	* 设备虚拟化: 配置，管理io space，路由io space operation
*  某些事件加速
	* CPUID 指令模拟
	* PMU模拟
***

而我们知道，虚拟机规格的定义是在qemu侧。所以，如果想让KVM "代 完成"某些职责，就需要一些接口来同步两侧的状态。另外，KVM某些职责也只完成一部分，其余部分需要QEMU完成。所以需要一套扩展的用户侧API。

# usespace API

在Linux中，一切皆文件。KVM也不列外，QEMU管理虚拟机通过打开`/dev/kvm` `misc`设备文件，管理KVM资源。

![[Excalidraw/KVM_file.excalidraw]]

而`open("/dev/kvm")`打开的`KVM fd`。可以通过`ioctl(KVM_CREAT_VM,)`接口获取`vm_fd`,  而又可以通过`ioctl(KVM_CREAT_VCPU)` 获取`vcpu fd`。

我们简单描述下这三个fd。

| fd type | 获取方式                         | 作用                                                      |
| ------- | ---------------------------- | ------------------------------------------------------- |
| kvm fd  | open("/dev/kvm")             | 创建vm fd; 并提供KVM 全局属性的信息获取。例如API version, vcpu mmap size |
| vm fd   | ioctl(kvm fd, KVM_CRATE_VM)  | 管理虚拟机资源，包括管理cpu，memory，irqchip等等                        |
| vcpufd  | kvm(vcpu fd, KVM_CREAT_VCPU) | 管理vcpu层面的资源，例如vcpu 运行，vcpu regs，msr等等                   |

ok， 我们分别来看下

## kvm file

kvm file通过`open("/dev/kvm",)`得到。

```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/linux/v7.1-rc3/virt/kvm/kvm_main.c"
LINES: "5563-5567, 5557-5561"
TITLE: "kvm_dev"
```

而该设备文件，只有一个接口，那就是`ioctl`，而`ioctl()`提供的子选项如下:

| sub option             | 作用                                                                                                                                                                             |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| KVM_GET_API_VERSION    | 获取KVM API VERSION，用于qemu 评估API兼容性                                                                                                                                              |
| KVM_CREATE_VM          | 创建虚拟机，返回文件描述符。                                                                                                                                                                 |
| KVM_CHECK_EXTENSION    | KVM支持一些额外的能力，这些能力可能由某些编译选项控制，所以需要qemu通过接口来check 某些功能KVM是否支持。                                                                                                                   |
| KVM_GET_VCPU_MMAP_SIZE | 每个vcpu 也是一个文件，这个文件支持mmap，mmap后，kvm和qemu就有一段内存可以高效通信，避免了用户态和内核态的copy。而mmap的动作需要QEMU来触发，其需要知道kvm需要多大的内存来mmap。不过我这里有个疑问, mmap_size的区域也是API，用户态(qemu)应该确切知道其数据结构格式包括大小。为什么这里还要动态获取 |
还有一些和`arch` 相关的子选项, 我们以x86为例:

| arch sub option         | 作用                     |
| ----------------------- | ---------------------- |
| KVM_GET_MSR_INDEX_LIST  | 获取kvm支持的MSR INDEX LIST |
| KVM_GET_SUPPORTED_CPUID | 获取kvm支持的cpuid array    |
| ...                     |                        |
## VM file

在`ioctl(kvm fd, KVM_CREATE_VM, )`接口中最终会创建`vm file`匿名文件.

```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/linux/v7.1-rc3/virt/kvm/kvm_main.c"
LINES: "5479-5480,5486,5492,5498"
TITLE: "kvm_dev_ioctl_create_vm"
COMMENTS:
  5486:
    找到一个还没有使用过的fd
  5492:
    创建初始化 struct kvm
  5498:
    创建`kvm-vm` anonfile
```

VM file同样只有`ioctl()`接口:

```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/linux/v7.1-rc3/virt/kvm/kvm_main.c"
LINES: "5466-5471"
TITLE: "kvm_vm_fops"
```
 
接口如下:

| sub option                    | 作用                                                                                                      |
| ----------------------------- | ------------------------------------------------------------------------------------------------------- |
| KVM_CREATE_VCPU               | 创建vcpu， 返回vcpufd                                                                                        |
| KVM_ENABLE_CAP                | 为当前虚拟机，使能某些CAP                                                                                          |
| KVM_CHECK_EXTENSION           | KVM支持一些额外的能力，这些能力可能由某些编译选项控制，所以需要qemu通过接口来check 某些功能KVM是否支持。                                            |
| KVM_SET_USER_MEMORY_REGION(2) | 内存虚拟化相关，设置memory region.                                                                                |
| KVM_CLEAR_DIRTY_LOG           | 和脏页管理相关                                                                                                 |
| KVM_IRQFD                     | irqfd（中断虚拟化相关)。允许guest通过irqfd直接注入中断                                                                     |
| KVM_IOEVENTFD                 | 和设备虚拟化相关，允许用户态通过`eventfd`向内核侧注册`[GPA range,eventfd]`的映射关系，当guest 写入该GPA触发`VM-exit`时，则通过`eventfd`通知guest |
| KVM_SIGNAL_MSI                | 和中断虚拟化相关。qemu通过该接口注入MSI到guest                                                                           |
| KVM_IRQ_LINE                  | 和中断虚拟化相关。qemu通过该接口注入IRQ到guest                                                                           |
| KVM_SET_GSI_ROUTING           | 和中断虚拟化相关。中断路由表。                                                                                         |
| KVM_CREATE_DEVICE             | #TODO                                                                                                   |
| KVM_RESET_DIRTY_RINGS         | 和dirty rings相关。（脏页管理)                                                                                   |
| KVM_CREATE_GUEST_MEMFD        | guest memfd #TODO                                                                                       |
另外，也有一些和ARCH相关的功能，我们以x86_64为例, 简单列举几个:
* KVM_CREATE_IRQCHIP
* KVM_SET_TSS_ADDR
* KVM_SET_IDENTITY_MAP_ADDR

## VCPU FILE

在`ioctl(vm fd, KVM_CREATE_VCPU, )` vcpu file:

```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/linux/v7.1-rc3/virt/kvm/kvm_main.c"
LINES: "4151-4152,4234,4109-4115"
TITLE: "kvm_vm_ioctl_create_vcpu()"
FONT_SIZE: "14px"
```

来看下`kvm_vcpu_fops`:

```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/linux/v7.1-rc3/virt/kvm/kvm_main.c"
LINES: "4098-4104"
TITLE: "kvm_vcpu_fops"
FONT_SIZE: "14px"
```

除了`ioctl()`接口，还有一个`mmap()`接口(前面提到过他的作用), 我们主要来看下`ioctl`

| sub option            | 作用                          |
| --------------------- | --------------------------- |
| **KVM_RUN**           | 告知KVM，要进入guest mode(运行vcpu) |
| KVM_GET(SET)_REGS     | get/set kvm_regs            |
| KVM_GET(SET)_MP_STATE | 设置MP state                  |
| KVM_SET_SIGNAL_MASK   | #TODO                       |
| ...                   |                             |

# qemu USE API

# 总结

* KVM存在的原因有两个:
	* 有些和硬件虚拟化的交互必须在内核态做
	* 在内核态做某些模拟，可以避免回退到qemu,减少用户态和内核态切换，提升效率
* KVM提供了userspace API， FILE 包含三类:
	* kvm file: 获取kvm相关信息, open("/dev/kvm", ...)
	* vm file: 控制vm 层面 kvm数据和行为
	* vcpu file: 控制cpu层面的kvm 数据和行为
* `kvm file, vm file`只提供`ioctl()`接口，而`vm file` 另外提供`mmap()`接口