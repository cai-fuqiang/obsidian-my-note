## 简述

QEMU 可以虚拟化出多个arch 的cpu，以及同一个arch下不同的CPU model。需要一些数据结构来承载这些类型的特征。而关于描述这些CPU model 的数据结构，也被qemu 进行了QOM 处理。

# 相关数据结构

我们这里只关心`x86 cpu model`, 该`class` 数据结构定义如下:
## X86CPUClass -- class

首先我们来看下`X86CPUClass` 向上向下继承关系如下:

![[Excalidraw/qemu_cpu_model_tree.excalidraw]]

* `TYPE_CPU`继承自`TYPE_DEVICE`
* `TYPE_{ARCH}_CPU`继承自`TYPE_CPU`
* 而`X86CPU_Definition[]`数组中定义着对各个model 的特征定义，在初始化流程中会根据这个"模版"来创建各个model的type class
* 剩余三个并不是固定特征的类型，而是根据"当前物理机"动态调整
	* base: 一个没有任何特性启用的基准 CPU 模型类型
	* max: 启用当前主机上加速器支持的所有特性
	* host: 直接映射到宿主机的 CPU 特性，功能上与 max 相似，但是只能用于 `kvm`加速器?
	#TODO
```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/qemu/v11.0.0/target/i386/cpu.h"
LINES: "2530-2554"
TITLE: "X86CPUClass"
```

其中`model`参数包含了描述该`cpu model`的一些子特征:

```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/qemu/v11.0.0/target/i386/cpu.c"
LINES: "2303-2344"
TITLE: "X86CPUModel, X86CPUDefinition"
FOLDABLE: true

COMMENTS:
  2305: |-
    cpu model name, e.g.
    * qemu64
    * phenom
    * Haswell
    等等
  2306:
    表示 CPUID 指令中基本功能范围（EAX=0 到 EAX=level）的最高叶子号
  2307:
    表示 CPUID 指令中扩展功能范围（从 EAX=0x80000000 开始）的最高叶子号
  2320:
    这个比较关键，用来描述model的各个feature leaf
```

关于`FeatureWordArray`定义:
```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/qemu/v11.0.0/target/i386/cpu.h"
LINES: "679-682,727-729,740"
TITLE: "FeatureWordArray"
```

另外, `builtin_x86_defs[]` 定义了很多 model 组成了一个数组:

```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/qemu/v11.0.0/target/i386/cpu.c"
LINES: "3539-3540,3541,3561,3593,3635,4265"
TITLE: "buildin_x86_defs[]"
```

我们以`Haswell` 为例，来看下数组一个成员的具体定义示例:
```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/qemu/v11.0.0/target/i386/cpu.c"
LINES: "3539-3540,4265-4281"
TITLE: "builtin_x86_defs[]"
FONT_SIZE: "14px"
```
* level: 表示cpuid base function最大为6(`range [0,6]`)
* features: 每个features成员都可以声明该 model上 cpuid leaf 所应该具有的能力。

而`base, host, max`三个类型TypeInfo的定义，则是单独定义。我们这里以max为例

```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/qemu/v11.0.0/target/i386/cpu.c"
LINES: "7269-7274"
TITLE: "max_x86_cpu_type_info"
```

## X86CPU -- instance

`X86CPU`数据结构定义:
```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/qemu/v11.0.0/target/i386/cpu-qom.h"
LINES: "31"
TITLE: "DEFINE X86_CPU"
```

```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/qemu/v11.0.0/include/hw/core/cpu.h"
LINES: "83-85"
TITLE: "DEFINE X86_CPU"
```

综合上面两个宏来看最终`X86CPU` 数据结构定义为`ArchCPU`

![[Excalidraw/qemu_X86_CPU_instance.excalidraw]]

`X86CPU`数据结构构成如上。代码如下:

```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/qemu/v11.0.0/target/i386/cpu.h"
LINES: "2321-2337"
TITLE: "struct ArchCPU"
```

其主要成员如下:
* `parent_obj`: 非架构特定的数据（下面会展开几个成员)
* `env` :  包含了重要的x86架构的CPU数据，包括相关寄存器(通用寄存器,ip, flags 等等)，异常中断信息以及CPUID信息等等。另外为了方便从`CPUState`直接访问`env`, `CPUState`中包含了一个`env_ptr`指针指向.

```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/qemu/v11.0.0/include/hw/core/cpu.h"
LINES: "484-485,491-497,"
TITLE: "CPUState"
COMMENTS:
  491:
    一个core有几个thread
  493:
    vcpu thread
  497: thread pid
```


```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/qemu/v11.0.0/target/i386/cpu.h"
LINES: "1983-1987,2001-2005,2022-2024,2315"
TITLE: "CPUArchState"
```

## 总结

* class相关
	* `X86CPUClass`定义了`X86CPU` type class, 而 `ArchCPU` 则定义instance
	* `builtin_x86_def[]`定义了很多类型的`x86 cpu model`，在初始化时，要根据这个数组成员信息创建/初始化相关的`X86CPUClass`
	* 除了上面提到的`buildin_x86_def[]`定义的 cpu model 外，还有另外三个 model type: `base, max, host`
* instance相关
	* `CPUState`包含了架构无关的数据
	* `CPUX86State`包含了大量CPU上下文
	*  `ArchCPU` 包含了架构相关的其他信息

# 相关流程

上面讲述了相关数据结构。

## CPU class type register


# 参考链接
1. [[QEMU-KVM源码解析与应用.pdf#page=261&offset=76,720,0|QEMU-KVM源码解析与应用, 4.4 QEMU CPU的创建]]
2. [[QEMU OBJECT MODEL]]
