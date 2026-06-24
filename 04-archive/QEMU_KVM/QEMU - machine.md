#TODO 

# 简介

machine  对应于 虚拟机的主板。对于x86 qemu来说，实现的主板主要有两套:
* 440fx(i440fx)
* q35

> [!PDF|note] [[QEMU-KVM源码解析与应用.pdf#page=142&selection=6,1,9,11&color=note|QEMU-KVM源码解析与应用, p.142]]
> > Intel 440FX（i440fx）是Intel在1996年发布的用来支持Pentium II的主板芯片，距今已有20多年的历史，是一代比较经典的架构。虽然QEMU已经能够支持更先进的q35架构的模拟，但是目前QEMU依然默认使用i440fx架构。
> 
> 

> Q35 的 细节见[1], 咱不关注 #TODO 

440fx 中包括什么呢?

![[Excalidraw/i440fx.excalidraw]]

主要包括南北桥部分:
* 北桥的作用为向上链接处理器，向下链接快速设备(PCI device)和南桥， 其包括
	* PMC(PCI Bridge and Memory Controller)
	* DBX(Data Bus Accelerator)：用来加速内存访问
* 南桥(piix3) 主要连接低速设备, 包括
	* IDE controller
	* USB controller
	* isa

而`I/O APIC`则是直接连接到处理器。

但是qemu的模拟要简单些，其不需要模拟类似于下面的组件:
* host bus
* memory controller
* DBX
等等。

所以，我们来看下QEMU(QEMU-KVM)应该负责模拟的组件:

* CPU, memory, IOAPIC, LAPIC
* 北桥
	* PCI tree
		* PCI host bridge
		* PCI device tree
* 南桥
	* IOAPIC
	* IDE,usb controller, isa, other device

而`CPU, memory, IOAPIC, LAPIC` 由 `KVM`完成，qemu主要负责对接`CPU, memory, IOAPIC, LAPIC` API, 以及 设备虚拟化工作。

而`machine` 功能在QEMU 中，也是通过QOM 框架描述的。我们接下来详细看下这部分。
# TYPE STRUCT
## Class
继承链:
```
PCMachineClass    =>
  X86MachineClass =>
  MachineClass    =>
  ObjectClass
```

`PCMachineClass`:

```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/qemu/v11.0.0/include/hw/i386/pc.h"
LINES: "83-96"
TITLE: "PCMachineClass"
```

(暂不过多描述 #TODO )

而`X86MachineClass`定义比较简单:
```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/qemu/v11.0.0/include/hw/i386/x86.h"
LINES: "30-35"
TITLE: "X86MachineClass"
COMMENTS:
  34: |-
    xrupt是interrupt的缩写, 当该标志位设置为 true 时，意味着QEMU在构
    建ACPI的MADT表时(build_xrupt_override())，会插入一个类型为 
    `ACPI_APIC_XRUPT_OVERRIDE` 的特殊表项
    
    这个表项会 覆盖（Override）IRQ 0（传统的中断请求线0）的默认行为，
    
    将其重新路由到IOAPIC（I/O高级可编程中断控制器）的一个专用GSl（全局系统中断）上。
    
    对于模拟标准PC的QEMU机器类型，如`pc-i440fx`或`pc-q35`，该标志通常为`true`,
    
    这符合真实PC硬件的标准行为
```


而`MachineClass` 则描述整个虚拟机, 信息简单举几个常用成员:

```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/qemu/v11.0.0/include/hw/core/boards.h"
LINES: "260-262,266,271,280-281,289,290-295"
TITLE: "MachienClass"
COMMENTS:
  266: |-
    machine name:例如: `pc`, `pc-i440fx-10.0`
  271: |-
    **实例初始化函数**, 也就是qemu初始化 "主板" 的主要流程函数
  280: |-
    * max_cpu: cpu最大数量（支持热插拔情况下)
    * min_cpu: cpu最小数量
  290:
    默认的一些配置和设备
```

## instance

继承链:
`PCMachineState -> X86MachineState->MachineState->Object`:

### PCMachineState

```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/qemu/v11.0.0/include/hw/i386/pc.h"
LINES: "24-39"
TITLE: "PCMachineState"
```

### X86MachineState

除了MachineState结构外，还包含一些X86 特有的数据，简单举例:

```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/qemu/v11.0.0/include/hw/i386/x86.h"
LINES: "37-39, 55, 61, 64"
TITLE: "X86MachineState"
```

### MachineState

而`MachineState`则包含一些架构通用的信息:
```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/qemu/v11.0.0/include/hw/core/boards.h"
LINES: "391-393,397-398,428-430,439"
TITLE: "MachineState"
COMMENTS:
  397:
    和BIOS相关
  428:
    内存配置，描述内存大小，热插拔内存最大大小，以及slots count
  439:
    描述CPU 拓扑
```

上面描述了`instance`, `class`相关定义，接下来我们看下,  x86 究竟定义了哪些Type，怎么定义的。

# TYPE DEFINE CODE

我们首先来看下定义 type的相关代码（宏定义)

## HOW TO DEFINE A MACHINE TYPE

前面提到过, x86 QEMU 主要模拟了两种主板类型:
*  q35
*  i440fx
这两种主板类型,  会在qemu版本演进过程中，有一些功能扩展, 所以会迭代出下面的machine type

* pc(default lastest qemu version)
	* `pc-i440fx-${major}.${minor}`: e.g.: `pc-i440fx-2.8`, `pc-i440fx-2.9`...`pc-i440fx-11.0`
* q35(default lastest qemu version)
	* `pc-q35-${major}.${minor}`: .e.g.: `pc-q35-2.8`, `pc-q35-2.9`... `pc-q35-11.0`

QEMU 应该完成上面所有 qemu版本的 machine定义.  无论是`i440fx`还是`q35` 最终都通过
`DEFINE_PC_VER_MACHINE()`, 来完成Machine Type定义:

**PC**:
```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/qemu/v11.0.0/hw/i386/pc_piix.c"
LINES: "396-400"
TITLE: "DEFINE_I440FX_MACHINE"
FONT_SIZE: "12px"
```

**q35**

```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/qemu/v11.0.0/hw/i386/pc_q35.c"
LINES: "333-340"
TITLE: "DEFINE_Q35_MACHINE"
FONT_SIZE: "12px"
```


我们会在下面详细介绍`DEFINE_PC_VER_MACHINE()`宏定义，以及其全部的参数，但是在这里，我们还是要简单解释下几个参数，以便更好理解上面的定义

`DEFINE_PC_VER_MACHINE` 有一个可变参数列表, 用来描述该machine的版本信息, 其包括:
* major
* minor
* micro
* `_unused_`: (这个没用到...)
* tag

另外, 第四个参数, 表示是不是default，类型(在不加`-M`参数时, machine的默认值)

定义 machine 有以下几种类型的宏:
* `DEFINE_XXX_MACHINE`: 普通定义，可变参数为`major`, `minor`, 仅定义当前`major.minor` machine type
* `DEFINE_XXX_MACHINE_AS_LATEST`: 和上面类似，只不过该宏定义，只定义最新类型，例如当前 QEMU版本为`11.0`, 该宏用来定义`pc-i440px-11.0` machine type。标记该`machine_type`为`default_machine`
* `DEFINE_XXX_MACHINE_BUGFX`: 增加了`micro`参数，用来作为某个版本的补丁版本。

接下来我们详细看下`DEFINE_PC_VER_MACHINE()`定义:

```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/qemu/v11.0.0/include/hw/i386/pc.h"
LINES: "290-320"
TITLE: "DEFINE_PC_VER_MACHINE"
FONT_SIZE: "14px"
```

`DEFINE_PC_VER_MACHINE()` 依靠`MACHINE_VER_SYM`定义了很多符号，这些符号都是由`MACHINE_VER_SYM`定义:

我们来展开下`MACHINE_VER_SYM` 这个宏定义，这个宏定义的作用是为各个machine生成唯一前缀的符号名称。

```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/qemu/v11.0.0/include/hw/core/boards.h"
LINES: "558,652-670"
TITLE: "MACHINE_VER_SYM"
FONT_SIZE: "14px"
```

`_MACHINE_VER_PICK` 宏定义就是取第六个参数作为结果。可以看`MACHINE_VER_SYM`, 当`__VA_ARGS__`数量为:

| `__VA_ARGS__` 数量 | 第六个参数位置(相对于最后一个可变参数) | 宏名称                 |
| ---------------- | -------------------- | ------------------- |
| 2                | 4                    | `_MACHINE_VER_SYM2` |
| 3                | 3                    | `_MAHCINE_VER_SYM3` |
| 4                | 2                    | `_MAHCINE_VER_SYM4` |
| 5                | 1                    | `_MAHCINE_VER_SYM5` |
由上面可知，如果传入几个参数就使用`_MACHINE_VER_SYM${__VA_ARGS__}`定义sym 前缀。

好，我们以
```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/qemu/v11.0.0/hw/i386/pc_piix.c"
LINES: "436"
TITLE: "DEFINE_I440FX_MACHINE_AS_LATEST(11.0)"
FONT_SIZE: "14px"
```

来看下定义了哪些符号:
* `pc_i440fx_machine_11_0_init`: 实例初始化函数(但不是`TypeInfo.instance_init` #TODO ) 
* `pc_i440fx_machine_11_0_class_init`: 类初始化函数
* `TypeInfo pc_i440fx_machine_11_0_info`:
	* **name**:  `pc_i440fx-11.0-machine`
	* **class_init**: `pc_i440fx_machine_11_0_class_init`
	* **parent**: `TYPE_PC_MACHINE`
* `pc_i440fx_machine_11_0_register`: 类型注册函数
* `type_init(pc_i440fx_machine_11_0_register)`

## WHY DEFINE DIFFERENT MACHINE TYPE

那定义这么多版本有什么用么，答案是热迁移兼容,  保证热迁移 可以从不同的qemu版本迁移。

链接 [3] 中详细讲述了兼容规则，简单来说, 一下三种情况支持热迁移
* qemu-5.2 -M pc-5.2 -> migrates to -> qemu-5.2 -M pc-5.2
* qemu-5.1 -M pc-5.1 -> migrates to -> qemu-5.1 -M pc-5.1
* qemu-5.2 -M pc-5.1 -> migrates to -> qemu-5.2 -M pc-5.1
* qemu-5.2 -M pc-5.1 -> migrates to -> qemu-5.1 -M pc-5.1
* qemu-5.1 -M pc-5.1 -> migrates to -> qemu-5.2 -M pc-5.1

也就是说，只要machine type相同，从高版本向低版本，或者从低版本向高版本迁移都是允许的。

Q: 这种兼容性从哪里做呢
A: 从高版本qemu做

我们来看下相关代码。
## HOW TO Maintaining Old Machine Compatibility

原因在上面的`class init`函数, 我们再展开一次:

```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/qemu/v11.0.0/include/hw/i386/pc.h"
LINES: "290,296-305"
TITLE: "DEFINE_PC_VER_MACHINE"
```

301行，按照上面讲述的`MACHINE_VER_SYM()`宏展开，并以`11.0`版本为例，该函数将是:
`pc_i440fx_machine_11_0_options()`函数:

由于，我当前看的代码是`v11.0`版本，所以这个machine type是最新的。不用做任何兼容。

```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/qemu/v11.0.0/hw/i386/pc_piix.c"
LINES: "431-434"
TITLE: "pc_i440fx_machine_11_0_options"
```

`pc_i440fx_machine_options()`函数, 初始化 `Class`部分字段，并且增加`compat props`:

```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/qemu/v11.0.0/hw/i386/pc_piix.c"
LINES: "402-416,427-429"
TITLE: "pc_i440fx_machine_options"
FONT_SIZE: "15px"
```

`compat_props_add()`函数，我们后面再展开，大概的作用是, 会设置某些Type的 props的默认值。
这个很有用，在`v11.0` qemu 版本 virtio_blk 加了一个新features，而`v10.0`中没有，就可以加一个`props`, 然后在`v10.0`, 的machine type中，将该prop 默人值设置为false，我们这边举个真实例子:

以`machine_10.2`为例:

```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/qemu/v11.0.0/hw/i386/pc_piix.c"
LINES: "438-445"
TITLE: "pc_i440fx_machine_10_2_options"
```

`10_2_options`函数，会继承执行`11_0_options`函数（执行高版本的），在此基础上，还会执行`compat_props_add()` 来更改默认的props值。

看下`hw_compat_10_2`, `pc_compat_10_2`, 两者区别如下:

* hw_compat_xx_x: 负责处理**跨架构、全局通用**的硬件兼容性
* pc_compat_xx_x: 专门处理**x86 PC平台（如i440fx、Q35机器）** 特有的硬件兼容性

```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/qemu/v11.0.0/hw/core/machine.c"
LINES: "41-44"
TITLE: "hw_compat_10_2"
```

```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/qemu/v11.0.0/hw/i386/pc.c"
LINES: "76"
TITLE: "pc_compat_10_2"
```

ok， 我们接下来看`v11.0`版本, `migrate-pr`的默认值:

```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/qemu/v11.0.0/hw/scsi/scsi-disk.c"
LINES: "3373,3386-3387"
TITLE: "scsi_block_properties(v11.0)"
FONT_SIZE: "14px"
```

默认值为true，我们再来看下`v10.2`版本:

```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/qemu/v10.2.0/hw/scsi/scsi-disk.c"
LINES: "3291-3304"
TITLE: "scsi_block_properties(v10.2)"
```

其中没有`migrate-pr`参数。

而该功能是在
```
 ab57b51f scsi: save/load SCSI reservation state
```
`v11.0.0-rc0`版本中添加

> [commit 链接](https://github.com/qemu/qemu/commit/ab57b51f1375b6a6f098a74c6f79207a9630948d)

ok, 我们回过头来展开 `compat_props` 相关数据结构和接口.

## compat_props

前面提到, 兼容的低版本machine，会定义两个`GlobalProperty` 数组, 其定义如下:

```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/qemu/v11.0.0/include/hw/core/qdev.h"
LINES: "416-422"
TITLE: "GlobalProperty"
FONT_SIZE: "14px"
```
*  **driver**  : 要更改的具体driver name
* **property**: 要更改的property name
* value: 更改后的具体值

而`compat_props_add()` 则是将预定义的`GlobalProperty`数组，连接到 arr(`MachineClass->compat_props`)中:

```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/qemu/v11.0.0/include/hw/core/qdev.h"
LINES: "424-432"
TITLE: "compat_props_add()"
FONT_SIZE: "14px"
```

在qemu初始化过程中，会将 这个数组放到一个全部变量中:

```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/qemu/v11.0.0/system/vl.c"
LINES: "2192-2195"
TITLE: "qemu_create_machine"
FONT_SIZE: "14px"
```

```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/qemu/v11.0.0/qom/object.c"
LINES: "517-521, 482-491"
TITLE: "object_set_machine_compat_props(), object_compat_props"
FONT_SIZE: "14px"
```

该数组有三个成员:
```
0: accelerator
1: machine
2: cmdline中转化
```

以`Device TypeInfo` 为例, 其会在`instance_post_init`中调用`object_apply_compat_props()`来设置这些props的值:

```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/qemu/v11.0.0/hw/core/qdev.c"
LINES: "891-893,896,682-683,688"
TITLE: "device_type_info, device_post_init()"
FONT_SIZE: "14px"
```

而`object_apply_comat_props()`则会将`object_compat_props[]`中的三个数组按照一定顺序，依次设置完成:

```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/qemu/v11.0.0/qom/object.c"
LINES: "533-541"
TITLE: "object_apply_compat_props"
FONT_SIZE: "14px"
```

其顺序是按照数组index，从小到大的顺序，另外，该流程又在`instance_post_init`流程中，所以在整个初始化流程中，props配置覆盖顺序如下:(`A-->B` 表示B被A覆盖)
```
qemu command line 
--> machine compat define
--> accelerator define
--> driver code static define
```


# 总结
我们先阶段性总结下上面内容:
* x86 定义了两种主板类型: (440fx, q35), qemu为了保证不同版本qemu 可以热迁移，设计了一套兼容方案
* 该方案为不同兼容版本qemu 定义了不同的machine type。例如v10.2, 命名为 `pc_i440fx-10.2-machine`, 而怎么做到兼容性呢。通过定义props，将两个版本不兼容的features 更改配置。（例如新增加的功能disable)
* 不只有 compat machine type可以修改props 默认值，
	* qemu command cmdline
	* accelerator
	也同样可以修改 `props`默认值，其有优先级顺序，其中`qemu command cmdline` 优先级最高，`compat machine type` 次之，`accelerator` 最低。

***

# machine init

接下来，对于qemu模拟主板而言，另一个主要的工作就是初始化。

而主板完全有qemu模拟，部分功能(`CPU, interrupt controller, memory virtualization`) 会移交给KVM做，但是相关的初始化流程，会在 主板初始化的流程中做。

调用流程如下:
```sh
main()
=> qemu_init()
   => qemu_create_machine()
      => machine_class = select_machine()
      ## 创建 Machine instance
      => current_machine = object_new_with_class()
   => qmp_x_exit_preconfig
      => qemu_init_board()
         => machine_run_board_init()
            => machine_class->init(machine);
               => pc_i440fx_init
                  => pc_init1
```

而`pc_init1()` 包含各个子系统的初始化，我们放到后面的文章中详细讲解。 #TODO 

![[Excalidraw/qemu_pc_init1.excalidraw]]

# 参考链接

1. [Q35 - QEMU](https://wiki.qemu.org/images/4/4e/Q35.pdf)
2. [deepseek DBX](https://chat.deepseek.com/share/yspxc62rajtjq0zrsz)
3. [QEMU DOC:  Backwards compatibility](https://qemu.readthedocs.io/en/v10.0.3/devel/migration/compatibility.html)