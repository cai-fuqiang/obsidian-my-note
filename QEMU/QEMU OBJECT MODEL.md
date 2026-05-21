---
tags:
  - qemu
aliases:
  - QOM
id: QEMU OBJECT MODEL
---
本篇文章，我们主要来介绍下QOM机制
主要参考 [[QEMU-KVM源码解析与应用.pdf#page=81&offset=76,307,0|QEMU-KVM源码解析与应用, 2.4 QOM介绍]]

# 简介

QOM 全称 QEMU Object Model, 是QEMU 使用面向对象的方式来进行抽象设计。面向对象包括封装，继承与多态。而qom就是根据自己自身的需求，设计的一套面向对象的框架。

面向对象的几个概念: 

* 封装: 将数据和操作封装在对象中，隐藏内部细节
* 继承: 子类可以继承父类的属性和方法，重用代码
* 多态: 对象可以根据具体类型表现不同行为，通过相同接口调用不同实现，提高灵活性和可扩展性。

我们会在下面的流程中讲解到qom是如何针对上面三种面向对象的特性进行设计的。

> 关于上面提到的面向对象的三大要素见 [[language/OOB|OOB]]

# QOM的class, instance, interface, type, object

而QOM 则是按照自己的需求重新设计了下, 增加了下面的几个概念:

* type

  type类似于C++中的class,  主要的承担的角色是对类型的定义。包括继承关系，该类对应的实体的属性（大小，对齐等等）。
  
  首先关于继承关系，面向对象语言的继承是非常优雅的，可以通过编译器自动生成继承关系，而在`QOM`中，这个机制是C编译器无法完成的，所以需要额外的机制（编码）来完成该工作。（QOM设计的还挺优雅的，我们下面会讲到）

  除了定义继承关系，type中还包括类似于面向对象语言中的自定义数据成员和方法的机制。但是这些机制被拆分到class(是QOM自己的class概念，不要和面向对象语言中的类搞混)和instance 中。
  
* class
  只是针对某一类object抽象出具有共同特征的封装集合。这个共同特征是说大家都有共同的数据成员，而是这些成员都有相同的值，类似于"const part"（当然也包括方法），"const part" 如何理解呢，例如对于edu设备类型，其`vendor_id`, `device_id` 都是一样的，所以就可以把这些成员定义到class中, 所以class 可以认为是这些实例的公共部分（也可以说常量部分）。搞这一套的目的是啥呢？我觉得最大的好处是省内存。

* instance

  而instance不同，instance 是每个object的 可变部分，每个object可以根据自己的信息自定义该部分，例如对于edu device来说, 其`io_region`, `irq_state`每个实例不一样，所以这些属于instance。

* interface

  interface的作用和面向对象语言中interface的作用很像。如果说继承是一种血缘继承，每个子类必须表明自己是哪个父类“生的”，而接口就是为了实现能力扩展，就跟额外学习技能一样。
  
  举个例子，老鼠的儿子会打洞。说明鼠儿继承了鼠爸会打洞的技能。但是鼠儿并不满足于此，他想打洞大的更快一些。于是报名了蓝翔，拿下了 挖掘机 skills（interface）。大家可能会想那直接在子类中直接实现 挖掘机 function() 不一样么。那不一样，interface 可以继承。例如，蓝翔老师会开挖掘机，他将挖掘机`interface()`实现了，学生就可以继承该`interface()`直接使用。当然也可以长江后浪推前浪，重新实现（扩展）该功能。另外`interface()` 是可以多继承的。例如，鼠儿还想从此不怕猫，于是又在新东方学习了厨师skills，只要猫来找茬，就直接调用做饭接口，给猫做一桌可口的饭菜。  
  
* object

  具体的对象实例.

我们画图总结下上面的意思。
![[Excalidraw/QOM type instance interface object.excalidraw]]

`C++`或者其他面向对象语言中的`class`类型是开箱即用的（编写代码，编译器帮忙做好相关数据结构的构建，继承和多态关系），无需程序编写者关心。而QOM也想达到类似的效果。让“模块”开发者只需要非常简单的注册代码+简单的接口，就可以使用QOM功能。

# HOW to USE QOM -- API

虽然说QOM实现较复杂，但是QOM 提供了较为简单的API。包括:
* 类型定义
	* TypeInfo: 用来定义type, 以EDU module 来说，为 `edu_types[]`
	* instance type: 用来定义instance, 以`edu module`来说，为 `EduState`
* 注册方法
	* DEFINE_TYPES()
	* type_init()
		* type_register_static()
* 对象初始化接口 new()
	* object_new()
	* object_new_with_class()
	* object_new_with_props() 
## USE API -- 类型定义(struct TypeInfo)

ok，我们来详细介绍.

* **name**: TypeName, 相当于type的唯一标识，当我们使用 `object_new()`接口时，作为参数传入
* **parent** : 定义继承关系，需要传入parent TypeName
* **instance_size** : instance 大小
* **class_size** : class 大小
* **abstract**: 当为true时，表示该`class` 不包含任何成员.
* some function
	* **class_init** : 初始化`class`
	* **instance_init** : 初始化 `instance`
* **interfaces**: 定义了一个`InstanceInfo` 数组
 ```cpp
 //仅包含一个字符串，用来指定Interface Type类型
 struct InterfaceInfo {
     const char *type;
 };
 ```
    
以`edu`为例:

* type

```c
static const TypeInfo edu_types[] = {
    {
        .name          = TYPE_PCI_EDU_DEVICE,
        .parent        = TYPE_PCI_DEVICE,
        .instance_size = sizeof(EduState),
        .instance_init = edu_instance_init,
        .class_init    = edu_class_init,
        .interfaces    = (const InterfaceInfo[]) {
            { INTERFACE_CONVENTIONAL_PCI_DEVICE },
            { },
        },
    };
    
static const TypeInfo conventional_pci_interface_info = {
    .name          = INTERFACE_CONVENTIONAL_PCI_DEVICE,
    .parent        = TYPE_INTERFACE,
};
```
值得注意的是`INTERFACE_CONVENTIONAL_PCI_DEVICE`也是一个由`TypeInfo`定义的类型。

* class: 其没有定义`class_size`, 说明其没有自定义的class成员，使用parent class, 所以其class 为`PCIDeviceClass`
```cpp
struct PCIDeviceClass {
    DeviceClass parent_class;

    void (*realize)(PCIDevice *dev, Error **errp);
	...
};
```
* instance
```cpp
struct EduState {
    PCIDevice pdev;
    MemoryRegion mmio;
	...
};
```

所以，我们看到，不仅`TypeInfo` 需要通过`parent`来映射其继承关系，还需要在`class`, `instance`相关数据结构中, 隐式包含继承关系(class第一个成员是父class，而instance第一个成员是父instance)

**那这里需要大家思考下，在目前的能力下能否实现，封装，继承和多态。**

封装，和继承不必多说。而多态的目的是父类对象调用子类方法，因为子类的`class` 中完全包含了父类（不是指针，而是类似于组合), 所以其可以自定义`class`  内容. 那也就达到了多态的目的.

## USE API - 类型注册

类型注册有什么作用呢? C++中我们定义了一个class，而在`main()`中我们就可以使用该class创建对象。

而QOM类型注册也是起到这个作用。在这个module的`.c`中写好了注册接口，对于模块开发者而言，这个类型就相当于初始化好了，在其他流程中便可以使用这个类型创建对象。

以`edu`为例:

```cpp
DEFINE_TYPES(edu_types)
```

就这么简单?

![[Pasted image 20260521154724.png]]

这也不是什么魔法，无非是将类型初始化流程在`object_new()`调用之前完成（或者是调用中完成）. 
## USE API - object_new()
`object_new()` 的是一个通用API, 其只有一个参数`type_name`, 返回值为当前type的object，我们在API 实现相关章节中介绍

## How to access

对于一个`object` 而言，访问的对象可能有三个:
* class
* instance
* interface
其访问就是属于那种比较蹩脚的，前面我们提到过，子类的`class`, `instance` 的第一个成员，为父类的`class`, `instance`。我们如果要访问父类，例如父class，我们可以从子类数据结构第一个成员去查找。无法像高级语言，直接用子类对象，调用父类成员或方法。

QOM 为了让这些流程变得稍微优雅，一般的做法是，定义一些宏来抽象这些操作，举两个例子
* 访问父类class
```cpp
static void edu_class_init(ObjectClass *class, const void *data)
{
    DeviceClass *dc = DEVICE_CLASS(class);
    PCIDeviceClass *k = PCI_DEVICE_CLASS(class);
    ...
}
```
* 访问父类`instance`
```cpp
static void edu_instance_init(Object *obj)
{
    EduState *edu = EDU(obj);
	...
}
```

`ObjectClass` 可以通过宏`DEVICE_CLASS` 转换为`DeviceClass`, 也可以通过`PCI_DEVICE_CLASS` 转换为`PCIDeviceClass`, 通过宏来实现父类子类之间的类型转换，确实比
```cpp
DeviceClass *dc = (struct DeviceClass *)(class);
```

要优雅。
> instance 转换 `Object->EduState` 同理.

![[Excalidraw/QOM_access_VS_C++_access.excalidraw]]

<font color="red" size=4>所以, 要访问哪个父类的成员或者方法，首先应该通过相关宏转换到该类型</font>

Ok, 下面将进入较硬核的环节 -- QOM 相关API的实现
# QOM implement

![[Excalidraw/QOM lifeline.excalidraw]]

上图描述了QOM的实现中涉及的主要入口函数。我这边新增了一些图形用于表示和高级语言对比。下面我们来主要解释下上面提到的流程. 但是在介绍相关流程之前，先介绍相关数据结构定义。TypeInfo 定义我们在 [[#USE API -- 类型定义(struct TypeInfo)]] 一章节中介绍了，下面我们介绍其他部分.

## API implement -- struct

主要包含两类数据结构。
* type 相关
	* TypeInfo(前面介绍过)
	* TypeImpl
	* ObjectClass
	* Object
* Interface 相关
	* InterfaceInfo(前面介绍过)
	* InterfaceImpl
	* InterfaceClass

我们先看下`type`相关
### API implement -- struct  TypeXXX 

| 类别                    | 作用                                                                        |
| --------------------- | ------------------------------------------------------------------------- |
| TypeInfo              | 用作代码中定义类型（API struct）, 运行时不访问                                             |
| TypeImpl              | 运行时存储类的元数据，例如class instance size, 还包括Type 之间的继承关系, 以及Type 与 Interface包含关系 |
| xxxClass(ObjectClass) | 运行时，类型data的承载体，例如 数据成员，虚函数表等等（函数指针成员)                                     |

> [!PDF|yellow] [[QEMU-KVM源码解析与应用.pdf#page=89&selection=5,8,9,19&color=yellow|QEMU-KVM源码解析与应用, p.89]]
> TypeImpl的数据基本上都是从TypeInfo复制过来的，表示的是一个类型的基本信息。在C++中，可以使用class关键字定义一个类型。QEMU使用C语言实现面向对象时也必须保存对象的类型信息，所以在TypeInfo里面指定了类型的基本信息，然后在初始化的时候复制到TypeImpl的哈希表中。
> 
>> 我个人认为TypeInfo负责提供一个清爽的API interface。而TypeImpl 会包含一些API的实现流程中使用的数据成员，使用者无需关心。

> NOTE
> 
> 那这里其实还有一个问题, `TypeImpl` 主要的作用是为了创建class，那为什么不直接创建class，而非得引入中间层呢? 个人认为QEMU 采用了LAZY的策略，当真正用该Type创建实例的时候，才会使用`TypeImpl` 创建class。所以需要TypeImpl class的元数据信息(纯属瞎猜 ) #guess


我们来看下`TypeImpl` 比`TypeInfo`增加的成员:
*  `TypeImpl *parent_type`:  父类型模版
* `ObjectClass *class`
* `int num_interfaces`
* `InterfaceImpl interfaces[MAX_INTERFACES]`： `InterfaceImpl`

再来看下`ObjectClass`
* `Type type: (TypeImpl *)`
* `GSList *interfaces`: `InterfaceClass` 链表
* `GHashTable *properties`: 公共部分的 `properties`
其作为所有Class的基类，定义了最基础的几个部分。

最后是`Object`, `Object`作为所有`instance`的基实例。包含这些`Object`最基本的功能 -- 生命周期管理, 和一些常用的成员:
* **`ObjectClass *class`** : 常用 成员
* **`Object *parent`**: 不知道有啥作用 #TODO
* **`GHashTable *properties`**: 私有的 `properties` 每个成员不一样
* **`ObjectFree *free`** : 销毁函数
* **`uint32_t ref`**: 引用计数

### API implement -- struct  TypeXXX 

前面提到过, `Interface`比较特殊，`Interface` 是一个特殊的`Type`, 每个Interface也会和 `Type` 相关的数据结构。那在实现层`Interface`其他数据结构定义啥:

```cpp
struct InterfaceImpl
{
    const char *typename;
};
```

`InterfaceImpl` : 只是用在`TypeImpl`引用Interface
```cpp
struct TypeImpl {
	...
	InterfaceImpl interfaces[MAX_INTERFACES];
};
```
那这里有个问题: **为什么不直接用TypeImpl** ? 这里我思考了比较久，我觉得他最大的作用，来是用来`copy` TypeInfo中的`InterfaceInfo` #guess

```cpp
struct InterfaceClass
{
    ObjectClass parent_class;
    /* private: */
    Type interface_type;
};
```

`InterfaceClass`和`ObjectClass`一样，作为基类存在. 这些数据结构，我们以edu为例，用一个长图来描述
### QOM implment

本章节我们从类型注册开始.
### 类型的注册

类型注册的入口API有:
* `DEFINE_TYPES(const TypeInfo *infos)`
* `type_register_static(const TypeInfo *info)`
* `type_register_static_array(const TypeInfo *infos, int nr_infos)`

我们展开`DEFINE_TYPES()`
```c
#define DEFINE_TYPES(type_array)                                            \
static void do_qemu_init_ ## type_array(void)                               \
{                                                                           \
    type_register_static_array(type_array, ARRAY_SIZE(type_array));         \
}                                                                           \
type_init(do_qemu_init_ ## type_array)
```
关于`type_init()`接口，和 QEMU model 实现相关，在 [[QEMU moudle]] 一文中讲述。这里我们只需要记住，这里定义的`do_qemu_init_xxxx()`将会在qemu 进程启动时，在`main()` 调用之前执行。那执行什么流程呢? 我们展开`type_register_static_array()`

```sh
type_register_static_array
=> foreach typeinfo
   ## 对每一个typeinfo 调用
   => type_register_static
      ## 每一个要注册的类型都要有父类型，基类为ObjectClass
      => assert(info->parent);
         => type_register_internal()
         => ti:TypeImpl = type_new(info);
         => type_table_add(ti);
```
### init 流程

```
_start
   => __libc_start_main_imp
      => foreach constructor:
      {
         do_qemu_init_pci_edu_register_types
            => register_module_init
               => alloc ModuleEntry
               => init it
               {
                 e->init
                 e->type
               }
               => link to init_type_list[e->type] list
      }
main
   => qemu_init
      => qemu_init_subsystems
         => module_call_init(MODULE_INIT_QOM)
            => foreach_list init_type_list[MODULE_INIT_QOM]
            {
               e->init(): pci_edu_register_types
            }
```
### pci_edu_register_types
```
pci_edu_register_types
=> define : TypeInfo edu_info
=> type_register_static
   => type_register
       => type_register_internal
          => type_new  :return TypeImpl* ti
             => {
                   alloc TypeInfo ti
                   ti->name = "edu"
                   ti->parent = "pci-device"
                   ...
                }
          => type_table_add
```

### type register

## 类型初始化

在介绍type register之前，我们首先介绍下
### type_initialize

```
type_initialize
   => alloc_class {
         init: ti->class_size:                 ## if not define, get parent 's class size
         init: ti->instance_size: 
         ti->class = g_malloc0(ti->class_size) alloc class
      }
   => init_class {
      如果是祖先interface type, 则需要判断一些东西， 
         例如instance_size必须是0
         abstract 必须是1 等等

   => init_parent_type and copy_class_from_parent 
   {
      => type_initialize(parent) :            ## 递归
      => memcpy(ti->class, parent->class, parent->class_size)   ## copy parent class
      => init_interface                       ## 这块逻辑有点怪，我们在后面贴下具体代码
   }
   => init properties: g_hash_table_new_full(g_str_hash, g_str_equal, NULL, object_property_free);
   => ti->class->type = ti                    ## 设置该class的type

   => while (parent = parent->parent) 
      parent->class_base_init()               ## 递归循环
   => ti->class_init()
}
```

该部分的逻辑是初始化TypeImpl, 其实主要的是初始化ti->class 和 interface , 在初始化本type的class时，
首先要将class->parent 初始化，以及其 class 的interface初始化.

我们展开下和interface相关的代码, 在看`type_initialize`相关代码之前，
我们先看下`type_initialize_interface`

```cpp
static void type_initialize_interface(TypeImpl *ti, TypeImpl *interface_type,
                                      TypeImpl *parent_type)
{
    InterfaceClass *new_iface;
    TypeInfo info = { };
    TypeImpl *iface_impl;

    info.parent = parent_type->name;
    info.name = g_strdup_printf("%s::%s", ti->name, interface_type->name);
    info.abstract = true;

    iface_impl = type_new(&info);
    iface_impl->parent_type = parent_type;
    type_initialize(iface_impl);
    g_free((char *)info.name);

    new_iface = (InterfaceClass *)iface_impl->class;
    new_iface->concrete_class = ti->class;
    new_iface->interface_type = interface_type;

    ti->class->interfaces = g_slist_append(ti->class->interfaces, new_iface);
}
```
该函数的作用是, get and init该interface的 `TypeImpl`, 需要做的动作大概是:
* init a TypeInfo
  + TypeInfo.name = "ti->name::interface_type->name"
  + Type.parent = parent_type->name 

    eg

    * `interface_type->name = vmstate-if`
    * `ti->name = cpu`
    * `interface_type->name = device::vmstate-if`
    * `TypeInfo.name = cpu::vmsate-if`
    * `TypeInfo.parent = device::vmsate-if`

  这样来看，是不是就有面向对象编程中，interface的作用了，
  如果底层有对interface的实现，则给他覆盖，而且能够实现对父类的覆盖


* alloc TypeImpl : type_new(TypeInfo)
* type_initialize(iface_impl)
* init InterfaceClass
  + concrete_clas = ti->class
  + interface_type = interface_type
* 将新分配的 interface 加入到 `ti->class->interfaces`

```cpp
static void type_initialize(TypeImpl *ti)
{
		...
		parent = type_get_parent(ti);
		if (parent) {
				//===(1)===
        for (e = parent->class->interfaces; e; e = e->next) {
            InterfaceClass *iface = e->data;
            ObjectClass *klass = OBJECT_CLASS(iface);

            type_initialize_interface(ti, iface->interface_type, klass->type);
        }

        for (i = 0; i < ti->num_interfaces; i++) {
            TypeImpl *t = type_get_by_name(ti->interfaces[i].typename);
            if (!t) {
                error_report("missing interface '%s' for object '%s'",
                             ti->interfaces[i].typename, parent->name);
                abort();
            }
						//===(2)===
            for (e = ti->class->interfaces; e; e = e->next) {
                TypeImpl *target_type = OBJECT_CLASS(e->data)->type;

                if (type_is_ancestor(target_type, t)) {
                    break;
                }
            }

						//===(2.1)===
            if (e) {
                continue;
            }
            //===(3)===
            type_initialize_interface(ti, t, t);
        }
    }
		...
} 
```
1. 调用查看`parent->class->interfaces`, 然后，根据parent interface，来init 
当前`ti->class->interface`
2. 查看当前的`ti->interfaces`, 然后和`ti->class->interfaces`中的每个进行对比，
   判断是否在（1）过程中添加过，如果添加过，则不需要再添加（2.1)
3. 执行到这里，说明ti中定义了新的interface，在父类中没有定义过，所以这里`parent_type:arg3`
   传递的仍然是t


### edu class init
```cpp
static void edu_class_init(ObjectClass *class, void *data)
{
    DeviceClass *dc = DEVICE_CLASS(class);
    PCIDeviceClass *k = PCI_DEVICE_CLASS(class);

    k->realize = pci_edu_realize;
    k->exit = pci_edu_uninit;
    k->vendor_id = PCI_VENDOR_ID_QEMU;
    k->device_id = 0x11e8;
    k->revision = 0x10;
    k->class_id = PCI_CLASS_OTHERS;
    set_bit(DEVICE_CATEGORY_MISC, dc->categories);
}
```
因为`edu` 这里 初始化 其父类，`PCIDeviceClass` 和 父类的父类`DeviceClass`, 
的部分成员。并将`k->realize`赋值为`pci_edu_realize`

下面展示`DEVICE_CLASS`宏, 我们看下如果通过当前的`ObjectClass`，找到相应的父类

> ObjectClass: 实际上是对所有类的抽象，其ObjectClass->type 指向的是当前类
> 的类型, 我们将此处的class认定为当前class（edu class), device class是其
> 父类
{: .prompt-tip}

<details markdown=1 open>
<summary>DEVICE_CLASS 展开, 以edu为例</summary>

```cpp
DEVICE_CLASS : this is a static function, declare here:

OBJECT_DECLARE_TYPE(DeviceState, DeviceClass, DEVICE)

OBJECT_DECLARE_TYPE(InstanceType:DeviceState, ClassType:DeviceClass, MODULE_OBJ_NAME:DEVICE)
  => DECLARE_OBJ_CHECKERS(InstanceType:DeviceState, ClassType:DeviceClass, MODULE_OBJ_NAME:DEVICE, TYPE_##MODLE_OBJ_NAME:TYPE_DEVICE)
     => DECLARE_CLASS_CHECKERS(ClassType:DeviceClass, OBJ_NAME:DEVICE, TYPENAME:TYPE_DEVICE)
        => {
              static inline DeviceClass * DEVICE_GET_CLASS(const void *obj)
              {
                 return OBJECT_GET_CLASS(DeviceClass, obj, TYPE_DEVICE);
              }
              static inline DeviceClass * DEVICE_CLASS(const void *klass) 
              {
                 return OBJECT_CLASS_CHECK(DeviceClass, klass,  TYPE_DEVICE);
              }
           } 
#define OBJECT_CLASS_CHECK(class_type, class, name) \
    ((class_type *)object_class_dynamic_cast_assert(OBJECT_CLASS(class), (name), \
                                               __FILE__, __LINE__, __func__))

    (DeviceClass *)object_class_dynamic_cast_assert(Objectclass *class, "device", ...)
```
可以看到，如果调用`DEVICE_CLASS(class)`, 先把`class`强转未`ObjectClass`,  然后调用
`object_class_dynamic_cast_assert`, 然后最终返回`DeviceClass *`,  我们来看下具体调用:

```
object_class_dynamic_cast_assert
   => object_class_dynamic_cast
      => type = class->type										## 获取该类的 TypeImpl
      => target_type = type_get_by_name() 		## 首先根据typename获取TypeImpl
      => 查看type所在的class是否有interfaces，如果有，查看target_type是否是interface类型
        => Y: 遍历class->interfaces 链表，看看哪个interface是target_type
              的子类型(type_is_ancestor)，如果是则说明找到了, 可以强转
        => N: 说明target_type不是interface
      => 查看target_type 是不是该type的父类型(type_is_ancestor), 如果是，则说明找到了，可以强转
   => 如果发现可以强转，返回 object, 如果发现不能强转，则返回NULL
```

所以`DEVICE_CLASS`作用是， 判断传入的class查看是否是继承的`DeviceClass`， 如果是则进行强转
`(DeviceClass *) class`, 如果不是， 则返回NULL

</details>

## object 初始化
现在注册好了类型，如果我们在qemu命令行执行`-device edu`, qemu则会使用前面定义好的类型
来创建一个object

以edu为例，在下面的流程中，会执行对该edu device的初始化:
```
main
 qemu_init
  qmp_x_exit_preconfig
   qemu_create_cli_devices
    qemu_opts_foreach
     device_init_func
```

简单看下`device_init_func`流程
```sh
device_init_func(QDict *opts, ...)        # opts 和字典相关，
=> driver = qdict_get_try_str(opts, "driver")      # 通过opts查询 driver, 返回"edu"
=> qdev_get_device_class(&driver, errp)   # 通过"edu"找到其class， 转换为DeviceClass
=> path = qdict_get_try_str(opts, "bus"); # 找到bus
=> dev = qdev_new(driver);
   => ObjectClass *oc = object_class_by_name(edu)  # 找到edu 的class
   => return DEVICE(object_new(name));    # 调用object_new , 然后强转为DeviceState实例
=> dev->opts = qdict_clone_shallow(opts);
=> object_set_properties_from_keyval()
=> qdev_realize(DEVICE(dev), bus, errp)   # 对该device实例化
   => qdev_set_parent_bus(dev, bus, errp); # 设置parent_bus
   => object_property_set_bool(OBJECT(dev), "realized", true, errp);
      {
         这里先不展开, 在device_class_init, 会通过
           object_class_property_add_bool(class, "realized",
              device_get_realized, device_set_realized)
         注册好"realized" 的get callbak和set callbak
      }
      => device_set_realized              # 代码比较多, 只看一个地方
         => dc->realize()                 # 这里回调用到pci_edu_realize
```


我们主要看下`object_new`

object new 流程：
```sh
object_new
=> ti = type_get_by_name(typename)        # 通过typename，找到TypeImpl
=> object_new_with_type(Type type:ti)
   => type_initialize(type)               # 如果该type没有初始化过，在这里初始化
   => alloc object instance 
      {
         size = type->instance_size;
         align = type->instance_align;
         这里会根据align_size的大小，选择是否对其分配，下面我们展开代码:
         obj = g_malloc() / qemu_memalign
				 obj_free = g_free / qemu_vfree
      }
      
   => object_initialize_with_type(obj, size, type)
      => memset(obj, 0, type->instance_size);
      => obj->class = type->class;
      => object_ref(obj)                  # org refcount
      => object_class_property_init_all(obj)  #和properties相关
      => obj->properties = g_hash_table_new_full()
      => object_init_with_type(obj, type);
         => 递归对obj以及parent 都调用 ti->instance_init()
      => object_post_init_with_type()
         => 递归， 对其 obj 以及parent调用 ti->instance_post_init()
```
> 这里需要注意的是, `object_init_with_type()`, 调用`ti->instance_init()`时，需要
> 先对父类进行init，再对子类， 而`object_post_init_with_type()`则相反。

看下`pci_edu_realize`

```sh
pci_edu_realize
  => pci_config_set_interrupt_pin(pci_conf, 1) # 设置interrupt_pin
  => msi_init(pdev, 0, 1, true, false, errp)   # 设置msi
  => timer_init_ms(&edu->dma_timer, ...)       # dma timer
  => memory_region_init_io(&edu->mmio, &edu_mmio_ops, edu, "edi-mmio", 1* MiB)
     # register mmio
  => pci_register_bar(pdev, 0, PCI_BASE_ADDRESS_SPACE_MEMORY, &edu->mmio)
     # register bar
```

经过上面流程，edu 实例已经初始化完成。

## qom properties

QOM为了便于管理对象，为每个class定义了properties

```cpp
struct ObjectClass
{
    ...
    GHashTable *properties;
    ...
}
```

每个Property object定义如下:
```cpp
struct ObjectProperty
{
    char *name;
    char *type;
    char *description;
    ObjectPropertyAccessor *get;
    ObjectPropertyAccessor *set;
    ObjectPropertyResolve *resolve;
    ObjectPropertyRelease *release;
    ObjectPropertyInit *init;
    void *opaque;
    QObject *defval;
}
```
* name: property name，key value
* type: property type, 类型名，例如bool, string, link
* init, get, set, resolve, release 则是注册的回调
* opaque: 指向一个具体的类型(type中指定的), 其内定义了更具体的回调

我们来看下几个具体类型:
```cpp
typedef struct BoolProperty
{
    bool (*get)(Object *, Error **);
    void (*set)(Object *, bool, Error **);
} BoolProperty;

typedef struct StringProperty
{
    char *(*get)(Object *, Error **);
    void (*set)(Object *, const char *, Error **);
} StringProperty;
```
以执行下面语句为例， 我们看下:
```
device_class_init
...
=> object_class_property_add_bool(class, "realized",
    device_get_realized, device_set_realized);
=> object_class_property_add_bool(class, "hotpluggable",
    device_get_hotpluggable, NULL);
...

```

我们来画下edu class 的图:
```
+--------------+    
|ObjectClass   |    
+--------------+  
|DeviceClass   |
|其他成员      |---------- PCIDeviceClass, 也就是edu class parent, 但是edu class并没有增加其他member
+--------------+     
|PCIDeviceClass|     
|其他成员      |      
+--------------+        
```
ObjectClass
```
+--------------------+           +---------------+
|ObjectClass         |    +------+               |
+--------------------+    |      +---------------+
|type:Type(TypeImpl*)+----+  
+--------------------+    
|interfaces:GSList   |  
+--------------------+
|properties          |
+--------------------+
```

图:

<details markdown=1 open>
<summary>DeviceClass->properity图示</summary>

```
 +-----------+
 |ObjectClass|
 +-----------+
 |           |
 +-----------+
 |properity  +---+------+-------------
 +-----------+   |      |
 |           |   |      |
 +-----------+   |      |
                 |      |
                 |   +-------+
                 |   |name   +--------- "realized"
                 |   +-------+
                 |   |type   +--------- "bool"
                 |   +-------+
                 |   |set    +--------- properity_set_bool
                 |   +-------+
                 |   |get    +--------- properity_get_bool
                 |   +-------+
                 |   |opaque +-------+  +-------------+
                 |   +-------+       +--+BoolProperty |
                 |                      +-------------+
                 |                      |get          +---- device_get_realized
                 |                      +-------------+
                 |                      |set          +---- device_set_realized
                 +--------+             +-------------+
                          |
                      +---+---+
                      |name   +--------- "hotpluggable"
                      +-------+
                      |type   +--------- "bool"
                      +-------+
                      |set    +--------- properity_set_bool
                      +-------+
                      |get    +--------- properity_get_bool
                      +-------+
                      |opaque +-----+    +------------+
                      +-------+     +----+BoolProperty|
                                         +------------+
                                         |get         +--- device_set_hotplugable
                                         +------------+
                                         |set         +--- NULL
                                         +------------+
```

</details>


### init

该成员是一个hash表，在type_initialize()初始化:
```cpp
type_initialize

=> ti->class->properties = g_hash_table_new_full(g_str_hash, g_str_equal, NULL,
                                                  object_property_free);
```

`g_hash_table_new_full`的参数依次为:
* hash_func: get key hash
* key_equal_func: compare key 
* key_destroy_func: free key
* value_destroy_func: free value

### add
上面列出来一些，这次，我们列举全:

```cpp
device_class_init
  => object_class_property_add_bool(class, "realized",
                               device_get_realized, device_set_realized);
  => object_class_property_add_bool(class, "hotpluggable",
                               device_get_hotpluggable, NULL);
  => object_class_property_add_bool(class, "hotplugged",
                               device_get_hotplugged, NULL);
  => object_class_property_add_link(class, "parent_bus", TYPE_BUS,
                               offsetof(DeviceState, parent_bus), NULL, 0);
```

以简单的bool类型为例:
```cpp
object_class_property_add_bool
   => BoolProperty *prop = g_malloc
   => prop->get = device_get_realized
   => prop->set = device_set_realized
   => object_class_property_add(class, "realized", "bool", 
      property_get_bool, property_set_bool,
      NULL,
      void * opaque: prop
      )
      => prop = g_malloc0(ObjectProperty)
      => init {
            prop->name
            prop->type
            prop->get, set, release, opaque
         }
      => g_hash_table_insert(class->properties, prop->name, prop)
```
### find

```cpp
ObjectProperty *object_class_property_find(ObjectClass *klass, const char *name)
{
    ObjectClass *parent_klass;

    parent_klass = object_class_get_parent(klass);
    if (parent_klass) {
        ObjectProperty *prop =
            object_class_property_find(parent_klass, name);
        if (prop) {
            return prop;
        }
    }

    return g_hash_table_lookup(klass->properties, name);
}
```
> NOTE: 自己理解
>
> 这里搜索`prop`时，有顺序要求么，为什么还要先递归search parent class
>
> 是因为在进行`type_realized`时，并没有继承property, 理论上也不允许
> 父类和子类有相同name 的 property, 所以，这里会search parent class，
> 并且search顺序无所谓
{: .prompt-info}

### set
```cpp
object_property_set_bool
  => object_property_set
     => ObjectProperty *prop = object_property_find_err
     => prop->set()    # property_set_bool
        => BoolProperty *prop = opaque
        => prop->set() # device_set_realized
```
流程比较简单，先find, 再set

## others

### gcc constructor attribute test
编写程序测试:

```cpp
#include <stdio.h>

void __attribute__ ((constructor)) before_main()
{
        printf("before main\n");
}

int main()
{
        printf("main exec \n");
}
```

执行程序获取输出:
```sh
➜  constructor_test ./main
before main
main exec
```

gdb 调试下:
```
#0  before_main () at main.c:5
#1  0x00007ffff7df5cc4 in __libc_start_main_impl () from /lib64/libc.so.6
#2  0x0000000000401065 in _start ()
```
发现在main前, 执行`_start`时，会执行constructor之前的函数
## 参考文献

[1]. <<QEMU-KVM 源码解析与应用>>

而C语言呢，似乎就没有这么简单
