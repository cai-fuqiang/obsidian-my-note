## 简述

QEMU 可以虚拟化出多个arch 的cpu，以及同一个arch下不同的CPU model。需要一些数据结构来承载这些类型的特征。而关于描述这些CPU model 的数据结构，也被qemu 进行了QOM 处理。

# 相关数据结构

我们这里只关心`x86 cpu model`, 该`class` 数据结构定义如下:
## X86CPUClass -- class
### X86CPUClass
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
FONT_SIZE: "14px"
```

其中`model`参数包含了描述该`cpu model`的一些子特征:

### X86CPUDefinition

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
#### features

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

`features[]`是一个数组,  其数组下标(e.g.(`FEAT_1_EDX`)) 在下面枚举中定义:

```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/qemu/v11.0.0/target/i386/cpu.h"
LINES: "678-682"
TITLE: "FeatureWord"
```

另外每个Feature bit(e.g. `CPUID_VME`) 其value 和`cpuid`指令返回的相关寄存器的值的相关位对应。(e.g. `CPUID_VME`, 其为cpuid指令: `cpuid[1].EDX[CPUID_VME]`)

```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/qemu/v11.0.0/target/i386/cpu.h"
LINES: "745"
TITLE: "CPUID_VME"
```

![[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=832&rect=41,638,563,727|325462-sdm-vol-1-2abcd-3abcd-4, p.832]]

另外, 这些features，还在`feature_word_info[]`数组中有字符串描述: 

```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/qemu/v11.0.0/target/i386/cpu.c"
LINES: "1043-1047"
TITLE: "feature_word_info"
```

***

而`base, host, max`三个类型TypeInfo的定义，则是单独定义。我们这里以max为例

```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/qemu/v11.0.0/target/i386/cpu.c"
LINES: "7269-7274"
TITLE: "max_x86_cpu_type_info"
```

#### versions

`-noTSX`, `-IBRS` 这类为特定功能开关创建的"特殊"CPU model，这种model往往某一两个feature 和其"母体"不同，所以将他们视为现有`model`的不同`version`。例如，“Nehalem-IBRS”被定义为Nehalem CPU的一个versions，而非独立的model。其和`Nehalem-IBRS`不同之处在于其多支持了`IBRS`feature)

```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/qemu/v11.0.0/target/i386/cpu.c"
LINES: "3539-3540,3928-3930,3989-4003"
TITLE: ""
FONT_SIZE: "14px"
```

可见，有两个versions, `version 1`就是`Nehalem`的"原始"版本，而`version 2` 才是基于`Hehalem`微调版本.

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

上面讲述了相关数据结构。下面我们来看下具体的流程。首先我们来关注，这么多cpu model 类型，是以何种流程注册的:
## CPU class type register

在介绍QOM文章中<sup>2</sup>中我们提到过，通过定义静态定义`TypeInfo`, 然后通过类型注册相关接口(e.g.`DEFINE_TYPES()`) 将类型注册，这样在qemu启动初，就可以将这些`TypeInfo`转换为运行时的`TypeImpl`.

然而编写这些`TypeInfo`有点麻烦(虽然一定程度上可以通过宏定义完成), 于是开发者选择了一种更简单直观的方式, 使用`builtin_x86_def[]` 定义固定特征的CPU model（这些占大部分）, 在初始化代码中动态生成`TypeInfo`注册(处理方式和interface类似), 另外三个`max`,`host`,`base`则继续用`TypeInfo`静态定义，代码如下:

```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/qemu/v11.0.0/target/i386/cpu.c"
LINES: "10827-10839"
TITLE: "x86_cpu_register_types"
```

`x86_register_cpudef_types()`代码如下:

```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/qemu/v11.0.0/target/i386/cpu.c"
LINES: "8391-8394,8404-8408,8429,8372-8382"
TITLE: "x86_register_cpudef_types() part1..."
FONT_SIZE: "14px"
```

该函数申请`X86CPUModel`, 并赋值`cpudef`成员，通过调用`x86_register_cpu_model_type()`注册该type, 而typename被`x86_cpu_type_name()`函数拼接(以`Haswell`示例如下 -- `HasWell-x86_64-cpu`)

***

前面还提到过，该cpu model 下有不同的`versions`, 而 `x86_register_cpudef_types()`也为不同的`version`创建了`type`:

```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/qemu/v11.0.0/target/i386/cpu.c"
LINES: "8391-8394,8412-8431"
TITLE: "x86_register_cpudef_types() -- part2"
FONT_SIZE: "14px"
```

`x86_cpu_versioned_model_name()` 会根据`def->name`以及version拼出一个新的name: `xxx-v1`, `xxx-v2`等等。而在`8420`行，会为所有的version都创建一个`xxxx-v..`的`Type`。另外，如果该version有别名的话，还需要在根据别名创建一个`Type`。

以`Nehalem` 为例，`x86_register_cpu_def_types()`执行过程中, 一共创建了4个`Type`:
* **Nehalem**: line-8408
* **Nehalem-v1**: line-8420
* **Nehalem-v2**: line-8420
* **Nehalem-IBRS**: line-8427
ok, 当前流程完成了`type register`, 而class init的流程如何实现的呢?

## CPU class type init

我们这里不关注`cpu class init`的流程是怎么触发的, 只去看下其`class_init`，相关的流程

上面设计的Type以及其class_init函数映射如下:

| name            | parent      | class_init()              |
| --------------- | ----------- | ------------------------- |
| cpu             | device      | cpu_common_class_init     |
| x86-cpu         | cpu         | x86_cpu_common_class_init |
| Nehalem-x86-cpu | x86-cpuG    | x86_cpu_cpudef_class_init |
| max-x86-cpu     | x86-cpu     | max_x86_cpu_class_init    |
| base-x86-cpu    | x86-cpu     | base_x86_cpu_class_init   |
| host-x86-cpu    | max-x86-cpu | host_cpu_class_init       |

我们首先来看下`cpu_common_class_init()`
### cpu_common_class_init
```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/qemu/v11.0.0/hw/core/cpu-common.c"
LINES: "369-375,380-381"
TITLE: "cpu_common_class_init()"
FONT_SIZE: "14px"
```

其初始化一些和架构无关的`dc`中的方法

其次我们来看下`x86_cpu_common_class_init()`
### x86_cpu_common_class_init

```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/qemu/v11.0.0/target/i386/cpu.c"
LINES: "10705-10709,10713-10717,10723-10728"
TITLE: "x86_cpu_commom_class_init() -- part1"
FONT_SIZE: "13px"
COMMENTS:
  10713:
    ---(1)---
  10723:
    ---(2)---
```
1. 调用`device_class_set_parent_realize()`该函数的作用是将`dc->realize`回调替换为`x86_cpu_realizefn`, 将原来的值赋值到`xcc->parent_realize`, 当调用到，而在`x86_cpu_realizefn`函数中，会调用`xcc->parent_realize`, parent_realize最终被赋值为`cpu_common_realizefn`
2. 初始化一些x86架构通用的方法

```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/qemu/v11.0.0/target/i386/cpu.c"
LINES: "10705-10706,10751-10756,10789-10795"
TITLE: "x86_cpu_commom_class_init() -- part2"
FONT_SIZE: "13px"
COMMENTS:
  10751:
    ---(3)---
  10789:
    ---(4)---
```
3. 增加一些property，注意这些property是x86架构通用的，并且是该类型共有的。
4. 为每个features分配property

好，我们来看下为features分配的property是什么类型

堆栈如下:
```sh
x86_cpu_register_feature_bit_props
## 获取feature的描述字符串
=> name = fi->feat_names[bitnr]
=> x86_cpu_register_bit_prop
   => BitProperty *fp
   => mask = (1ULL << bitnr)
   => op = object_class_property_find(oc, prop_name)
   => if op
      \-> fp = op->opaqua
      ## 如果用一个字符串，则需要在一个cpuid (index,leaf,reg) 中
      \-> assert(fp->w == w)
      \-> fp->mask |= mask
   -> else
      ## new
      \-> fp = g_new0(BitProperty, 1)
      \-> fp->w = w
      \-> fp->mask = mask
      \-> object_class_property_add(,,bool)
```
可以看到分配的是`bool`类型，请注意, 从代码实现看起来允许定义多个 cpuid bit 名称设置成一样的。但是有限制，必须是同一个 `cpuid (index,leaf, reg)` 也就是`FeatureWorld`

而剩下的 type `class_init`是和不同cpu model 相关。而CPU model 往往只是features不同。所以实现上较简单，我们暂不展开这些内容。

好上面讲述完了 `class type` 的注册和初始化部分。接下来，我们来看instance部分:
## instance init

`cpu instance_init()`触发堆栈:
```
machine_run_board_init()
=> pc_i440fx_machine_10_0_init()
   => pc_i440fx_init()
      => pc_init1()
         => x86_cpus_init()

x86_cpus_init()
=> for (i = 0; i < ms->smp.cpus; i++)
   \-> x86_cpu_new(x86ms, possible_cpus->cpus[i].arch_id, &error_fatal);
```

其会根据`smp`的数量，批量创建 `instance`

`instance_init()` 和`realize()`接口的区别是:

`instance_init()`只是去将相关数据结构初始化，而`realize()`则是为设备运行准备好(初始化好)其他的资源。

| name            | parent      | instance_init()    |
| --------------- | ----------- | ------------------ |
| cpu             | device      | cpu_common_initfn  |
| x86-cpu         | cpu         | x86_cpu_initfn     |
| Nehalem-x86-cpu | x86-cpu     | N/A                |
| max-x86-cpu     | x86-cpu     | max_x86_cpu_initfn |
| base-x86-cpu    | x86-cpu     | N/A                |
| host-x86-cpu    | max-x86-cpu | N/A                |
### cpu_common_initfn
```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/qemu/v11.0.0/hw/core/cpu-common.c"
LINES: "301-303,313-315,316-322"
TITLE: "cpu_common_initfn"
FONT_SIZE: "14px"
COMMENTS:
  315: |-
    这里先设置为1，对于user-mode 不会配置smp 拓扑，而对于system mode，则会在后面的
    realize流程中，通过 `qemu_init_vcpu()`重新设置该值
```

### x86_cpu_initfn
```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/qemu/v11.0.0/target/i386/cpu.c"
LINES: "10340-10351, 10355-10357, 10391-10401"
TITLE: "x86_cpu_initfn"
COMMENTS:
  10348:
    为"feature-words" 和 "filtered-features"增加查询接口方便
    其他流程查询
  10355:
    为很多features property 增加了别名
  10392: |-
    通过`x86_cpu_load_model()` 将model 模版中的信息
    加载到env中, 包含:
    + def->family,mode,stepping,vendor --> property
    + def->features[] -> env->features[w]
  10401: |-
    **待展开**
```

`accel_cpu_instance_init()`函数和加速器初始化相关,  每个加速器都会根据当前架构注册一个TypeInfo, 以`kvm x86_64` 为例为 `kvm-accel-x86_64-cpu`:

```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/qemu/v11.0.0/target/i386/kvm/kvm-cpu.c"
LINES: "243-249"
TITLE: "kvm_cpu_accel_type_info"
COMMENTS:
  244: |-
    ```
    #define CPU_RESOLVING_TYPE TYPE_X86_CPU
    ...
    #define TYPE_ACCEL_CPU "accel-" CPU_RESOLVING_TYPE
    #define ACCEL_CPU_NAME(name) (name "-" TYPE_ACCEL_CPU)
    ```
```

在`class_init`中会初始化该 instance `init`, `realize`等回调，用于处理和该加速器相关的额外步骤:

```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/qemu/v11.0.0/target/i386/kvm/kvm-cpu.c"
LINES: "236-242"
TITLE: "kvm_cpu_accel_class_init()"
```

而`accel_cpu_instance_init()`最终会调用到`acc->cpu_instance_init()`, 该函数实现如下:

```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/qemu/v11.0.0/target/i386/kvm/kvm-cpu.c"
LINES: "210-215,229-234"
TITLE: "kvm_cpu_instance_init()"
FONT_SIZE: "14px"
COMMENTS:
  215: |-
    如果是`xcc->max_features`(max, host), 会根据host的`family`, `model`, `stepping`
    初始化(set)相关的`property`
  229: |-
    初始化 `pmu`, `lmce` property, 通过cpuid 获取相关feature深度
    + env->cpuid_min_level :  function 0x0
    + env->cpuid_min_xlevel:  function 0x8000 000
    + env->cpuid_min_xlevel2: function 0xC000 000
```

***

`max_x86_cpu_initfn()`主要初始化默认的`vendor`, `model-id`等property 不展开
## instance realize

`realize()` 是`dc`(`DeviceClass)`的一个接口, 其主要的目的是，让为Device 准备好运行其所需的资源（环境）。

```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/qemu/v11.0.0/include/hw/core/qdev.h"
LINES: "115,174-175"
TITLE: "DeviceClass -- realize"
FONT_SIZE: "13px"
```

| name            | parent      | realize()            |
| --------------- | ----------- | -------------------- |
| cpu             | device      | cpu_common_realizefn |
| x86-cpu         | cpu         | x86_cpu_realizefn    |
| Nehalem-x86-cpu | x86-cpu     | N/A                  |
| max-x86-cpu     | x86-cpu     | N/A                  |
| base-x86-cpu    | x86-cpu     | N/A                  |
| host-x86-cpu    | max-x86-cpu | N/A                  |
### cpu_common_realizefn

```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/qemu/v11.0.0/hw/core/cpu-common.c"
LINES: "247-271"
TITLE: "cpu_common_realizefn"
FONT_SIZE: "14px"
```

#SKIP

## x86_cpu_realizefn
该函数特别长，我们摘取一些我们所关心的片段:

```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/qemu/v11.0.0/target/i386/cpu.c"
LINES: "9895-9896,9930,9971-9978,9998,10148,10161,10169-10171"
TITLE: "x86_cpu_realizefn"
COMMENTS:
  9930: |-
    详细解释 [^host_cpuid]
    
    [^host_cpuid]: |-
      对于`xcc->max_feature == true` 的cpu module来说(max,host),
      其需要根据物理机支持的cpuid来设置guest cpuid feature
      ```embed-cpp
      PATH: "https://raw.githubusercontent.com/cai-fuqiang/qemu/v11.0.0/target/i386/cpu.c"
      LINES: "9528-9529,9555-9563"
      TITLE: "x86_cpu_realizefn"
      ```
      但是`host cpuid`的获取也不是直接从user mode中调用`cpuid`指令获取，而是通过下面
      的调用流程
      ```
      kvm_arch_get_support_cpuid
        get_supported_cpuid()
          try_get_cpuid()
            kvm_ioctl(s, KVM_GET_SUPPORTED_CPUID, cpuid)
      ```
      从kvm测获取cpuid
  9971: |-
    详细解释[^filter_features]
    
    [^filter_features]: |-
      filter_features常常用在builtin define model, 用于过滤掉host 不支持的features.
      关于filter_features, 我们应该关注两个property
      
      ```embed-cpp
      PATH: "https://raw.githubusercontent.com/cai-fuqiang/qemu/v11.0.0/target/i386/cpu.c"
      LINES: "9727-9728,9743-9748"
      TITLE: "x86_cpu_filter_features"
      COMMENTS:
        9747: |-
          * `~host_feat`: host(kvm)不支持(guest 设置)的 features
          * `requested_features`: 用户期望使能的features
          * `requested_features & ~host_feat`:
                 用户期望使能而host(KVM)不支持
      ```
  10161: |-
    详细解释 [3]
```

我们来展开下`[3]`

`qemu_init_vcpu()`

```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/qemu/v11.0.0/system/cpus.c"
LINES: "709-710,714,726-731"
TITLE: "qemu_init_vcpu"
COMMENTS:
  714: |-
    将`cpu->stopped`设置为true，当创建了vcpu thread，vcpu thread也会阻塞在用户态，
    等待主线程将`cpu->stoppped`置位为false
    
    详细解释展开: [^cpu_stopped]
   
    [^cpu_stopped]: |-
      这里
      ```embed-cpp
      PATH: "https://raw.githubusercontent.com/cai-fuqiang/qemu/v11.0.0/accel/kvm/kvm-accel-ops.c"
      LINES: "31-32,50,53-54,58-59"
      TITLE: "kvm_vcpu_thread_fn"
      COMMENTS:
        53: |-
          ```
          cpu_can_run
          => if cpu->stop return false
          => if cpu->stopped return false
          ```
      ```
 
  726: |-
    创建vcpu thread，并做一些简要的初始化
  728: |-
    等待cpu thread 创建完成
    
    ```embed-cpp
    PATH: "https://raw.githubusercontent.com/cai-fuqiang/qemu/v11.0.0/accel/kvm/kvm-accel-ops.c"
    LINES: "31-32, 47"
    TITLE: "kvm_vcpu_thread_fn"
    COMMENTS:
      47:
        //cpu->created = true
    ```
 
```

ok, 创建vcpu线程后, 在KVM侧还会继续做一些初始化工作.  关于KVM的部分，这里我们放到另外一篇文章中讲。
# 总结

我们总结下整篇文章。
1. 关于CPU TYPE, qemu这边用了QOM的机制,  Type分为以下几层
	* CPU: (架构无关的信息), 继承自device
	* X86-64_CPU: x86 架构但是和具体CPU型号无关的cpu
	* xxx-X86-64-CPU: x86 特定型号的cpu信息
2. 关于CPU model type，x86 预定义了一些固定features的cpu model，用于在不同型号的物理机上运行相同features的vcpu，方便热迁移。除了固定features 的cpu model，qemu还定义了
	* base: 最小feature
	* host: host kvm 最大能支持的features集
	* max: host 最大支持的features集（不用于kvm) #guess
	 三种特殊架构
3. 关于各个型号的, 都会创建单独的class type, 并在`machine init`相关流程中，批量创建instance
4. `init_instance`和`realize`是两个不同的功能，初始化`instance`只是去准备qemu的相关资源，例如数据结构所需的内存空间，create property, 而`realize`则是为cpu device 能正常运行做充足准备，对于vcpu来说，就是和kvm 做好充分交互（初始化），并最终创建一个vcpu thread来承接 vcpu 运行。


# TODO

本篇文章主要是讲解了, 和`CPU model` 类型相关的:
* 类型定义
* class init, instance init , realize 大致的流程
而这些初始化流程设计各个子 features的初始化，这些细节并未涉及太多。等后续关注到某个具体的feature，或者功能时，再单独开文章记录。

目前想顺着该文章继续学习的点:
* 前面讲到了创建vcpu thread，但是并未讲vcpu thread 创建后，又做了哪些初始化
* 关于features部分，想单独开一个章节理清楚：
	* 用户侧API
	* qemu 中的具体的流程
	* KVM侧API
		* QEMU于KVM 侧API 交互细节
		* KVM API流程
# 参考链接
1. [[QEMU-KVM源码解析与应用.pdf#page=261&offset=76,720,0|QEMU-KVM源码解析与应用, 4.4 QEMU CPU的创建]]
2. [[QEMU OBJECT MODEL]]
