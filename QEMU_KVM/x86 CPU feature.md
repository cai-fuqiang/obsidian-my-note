---
id: 1779263474-IPIP
aliases:
  - cpu init (features)
tags:
  - qemu
---
## 相关代码片段记录

### -cpu option 相关代码片段

参数定义

```
DEF("cpu", HAS_ARG, QEMU_OPTION_cpu,
    "-cpu cpu        select CPU ('-cpu help' for list)\n", QEMU_ARCH_ALL)
```

`cpu_option` 赋值变量
```
static const char *cpu_option;
```

`current_machine`类型
```
MachineState *current_machine;
```

`current_machine->cpu_type` 中会存储`cpu_type`:
```sh
qemu_init
## 1. 假设这里设置的是 -cpu host, 那么 current_machine->cpu_type = "host-x86_64-cpu"
=> current_machine->cpu_type = parse_cpu_option(cpu_option);
```
1. `host-x86_64-cpu` 怎么来的呢

`parse_cpu_option` 会通过下面的调用栈获取该参数(本例子中是`host`)
对应的的typename, `-cpu`除了可以指定`host` 外, 可以用`,` 添加一系列的参数,e.g.:

```
-cpu host,avic=on,tsc-adjust=off
```

* `avic,tsc-adjust` : 表示相关cpu features
* `on, off` : 表示这些cpu features 在本次虚拟机启动是要开启/关闭.

  所以`parse_cpu_option()` 也需要负责上面的参数解析
  
  ```sh
  parse_cpu_option
  ## 按照 ',' 切分字符串
  => model_pieces = g_strsplit(cpu_option, ",", 2);
  ## ObjectClass os
  => oc = cpu_class_by_name(target_cpu_type(), model_pieces[0]);
     ## 这里的typename 为`x86-cpu`, 是要获取`x86-cpu` 的type
     ## 整个object 继承层级为:
     => oc = object_class_by_name(typename);
     ## object->device->cpu->x86-cpu->host-x86-cpu
  
     ## 而下面就是要查找 host-x86-cpu
     => oc = cc->class_by_name(cpu_model);
        ## x86_cpu_class_by_name
        ## 该函数很简单, 通过 首先构造字符串 "cpu-model" + x86-cpu
        ## 然后从 type_table hash table 中找到该type对应的 TypeImpl
        ##
        ## 然后将将type初始化，找到器class返回, 不展开这部分内容
     ## 获取 "host-x86-cpu"
     => cpu_type = object_class_get_name(oc);
     ## !! 处理 后续的feature on/off 相关参数
     => cc->parse_features(cpu_type, model_pieces[1], &error_fatal);
        ## 可以简单理解将参数解析，将根据on/off 分别将feature 串联到
        ## plus_features, minus_features 链表上
  ```

## cpu-type

x86 `cpu-type` 主要包含三类:

* `builtin_x86_defs`
* `max_x86_cpu_type_info`
* `host_x86_cpu_type_info`

```cpp
static const TypeInfo host_cpu_type_info = {
    .name = X86_CPU_TYPE_NAME("host"),
    .parent = X86_CPU_TYPE_NAME("max"),
    .class_init = host_cpu_class_init,
};
static const TypeInfo max_x86_cpu_type_info = {
    .name = X86_CPU_TYPE_NAME("max"),
    .parent = TYPE_X86_CPU,
    .instance_init = max_x86_cpu_initfn,
    .class_init = max_x86_cpu_class_init,
};
```
