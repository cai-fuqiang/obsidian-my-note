QEMU model 类似于内核model，以模块的形式可以插入某些功能，例如某些对某些设备的支持。但是qemu model 和kernel model 还有很大功能上的差异:

| feature  | kernel support | QEMU support |
| -------- | -------------- | ------------ |
| 静态加载模块   | Y              | Y            |
| 动态加载删除模块 | Y              | N            |
| 定义模块依赖   | Y              | Y            |
| 定义模块参数   | Y              | Y            |
OK，我们先来看下模块静态加载.

## 静态加载

何为静态加载，无非就是将模块代码编译进可执行文件，并且在合适的时机执行模块的初始化函数.

QEMU 为模块定义了如下类型。

```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/qemu/v11.0.0/include/qemu/module.h"
LINES: "42-53"
TITLE: "module_init_type"
```

并且定义了如下宏来注册初始化回调函数。
```cpp
#define block_init(function) module_init(function, MODULE_INIT_BLOCK)
#define opts_init(function) module_init(function, MODULE_INIT_OPTS)
#define type_init(function) module_init(function, MODULE_INIT_QOM)
...
```

展开看下`module_init()`宏展开:
```cpp
#define module_init(function, type)                                         \
static void __attribute__((constructor)) do_qemu_init_ ## function(void)    \
{                                                                           \
    register_module_init(function, type);                                   \
}
```

其定义了一个`__attribute__((constructor))` GCC修饰的函数。关于该修饰定义:
> [!PDF|important] [[armclang_reference_guide_100067_0611_00_en.pdf#page=148&selection=4,0,9,8&color=important|armclang_reference_guide_100067_0611_00_en, p.148]]
> This attribute causes the function it is associated with to be called automatically before main() is entered.

其可以指定一个参数, 参数越小，执行越靠前。如果不带任何优先级，那就是老末。

> [!PDF|yellow] [[armclang_reference_guide_100067_0611_00_en.pdf#page=148&selection=17,0,23,30&color=yellow|armclang_reference_guide_100067_0611_00_en, p.148]]
> Where priority is an optional integer value denoting the priority. A constructor with a low integer value runs before a constructor with a high integer value. A constructor with a priority runs before a constructor without a priority

`[0,100]` 优先级预留用作其他用途，如果要执意使用，则会报`warning`

> [!PDF|yellow] [[armclang_reference_guide_100067_0611_00_en.pdf#page=148&selection=24,0,25,15&color=yellow|armclang_reference_guide_100067_0611_00_en, p.148]]
> Priority values up to and including 100 are reserved for internal use. If you use these values, the compiler gives a warning


类型注册相关函数, 早于main执行

```sh
Breakpoint 4, do_qemu_init_pci_edu_register_types () at ../hw/misc/edu.c:442
442     type_init(pci_edu_register_types)
(gdb) bt
#0  do_qemu_init_pci_edu_register_types () at ../hw/misc/edu.c:442
#1  0x00007ffff67f3cc4 in __libc_start_main_impl () at /lib64/libc.so.6
#2  0x0000555555884885 in _start ()
```

![[Excalidraw/qemu_moduel_init.excalidraw]]

机制总结如上图

我们接下来看下`register_module_init()`:

```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/qemu/v11.0.0/util/module.c"
LINES: "70-82"
TITLE: "register_module_init"
```

其主要的流程是构造`ModuleEntry`, 然后在根据具体的`module_init_type`类型连接到不同的链表上。例如下图
![[Excalidraw/qemu_module_init_type_list]]

然后在下面的流程中会调用注册的相关callback
```
main
   => qemu_init
      => qemu_init_subsystems
         => module_call_init(MODULE_INIT_QOM)
            => foreach_list init_type_list[MODULE_INIT_QOM]
            {
               e->init(): pci_edu_register_types
            }
```

