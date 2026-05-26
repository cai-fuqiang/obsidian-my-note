## 简述

QEMU 可以虚拟化出多个arch 的cpu，以及同一个arch下不同的CPU model。需要一些数据结构来承载这些类型的特征。而关于描述这些CPU model 的数据结构，也被qemu 进行了QOM 处理。继承关系如下:
![[Excalidraw/qemu_cpu_model_tree.excalidraw]]

我们这里只关心`x86 cpu model`, 该class 数据结构定义如下:

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

## 参考链接

1. [[QEMU-KVM源码解析与应用.pdf#page=261&offset=76,720,0|QEMU-KVM源码解析与应用, 4.4 QEMU CPU的创建]]