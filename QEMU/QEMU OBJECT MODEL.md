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

  而instance描述的具体的实例对象，首先其有指向`class`的指针。用于访问该类型的`const part`,其次，其数据结构中，添加了一些`variable part`。两者共同构成了具体的实例。

* interface

  interface的作用和面向对象语言中interface的作用很像。如果说继承是一种血缘继承，每个子类必须表明自己是哪个父类“生的”，而接口就是为了实现能力扩展，就像外挂技能一样。
  
  举个例子，老鼠的儿子会打洞。说明鼠儿继承了鼠爸会打洞的技能。但是鼠儿并不满足于此，他想打洞大的更快一些。于是报名了蓝翔，拿下了 挖掘机 skills（interface）。大家可能会想那直接在子类中直接实现 挖掘机 function() 不一样么。那不一样，interface 可以继承。例如，蓝翔老师会开挖掘机，他将挖掘机`interface()`实现了，学生就可以继承该`interface()`直接使用。当然也可以长江后浪推前浪，重新实现（扩展）该功能。另外`interface()` 是可以多继承的。例如，鼠儿还想从此不怕猫，于是又在新东方学习了厨师skills，只要猫来找茬，就直接调用做饭接口，给猫做一桌可口的饭菜。  

  interface有如下限制:
  * interface 只定义方法, 不定义其他成员。
  * `interface` 只定义方法，不实现方法，需要继承者自己实现
  * QOM的`interface` 不能通过`TypeInfo.interfaces[]` 关联其他`interface`

我们画图总结下上面的意思。
![[Excalidraw/QOM type instance interface object.excalidraw]]

`C++`或者其他面向对象语言中的`class`类型是开箱即用的（编写代码，编译器帮忙做好相关数据结构的构建，继承和多态关系），无需程序编写者关心。而QOM也想达到类似的效果。让“模块”开发者只需要非常简单的注册代码+简单的接口，就可以使用QOM功能。

# HOW to USE QOM -- API

虽然说QOM实现较复杂，但是QOM 提供了较为简单的API。包括:
* 类型定义
	* TypeInfo: 用来定义type, 以EDU module 来说，为 `edu_types`
	* instance type: 用来定义instance, 以`edu module`来说，为 `EduState`
	* class type: 用来定义class，以edu module为例，为`EduClass`
* 注册方法
	* DEFINE_TYPES()
	* type_init()
		* type_register_static()
* 对象初始化接口 new()
	* object_new()
	* object_new_with_class()
	* object_new_with_props() 
## USE API -- 类型定义(struct TypeInfo)

```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/qemu/v11.0.0/include/qom/object.h"
LINES: "476-495"
TITLE: "TypeInfo"
```

TypeInfo成员如下:

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

以`edu` 为例，我们补一个图:
![[Excalidraw/TypeInfo_Class_instance]]

父`class`和子`class`的关系也是仿照面向对象语言编程多态的语义，其会子类型在创建class/instance时，会包含父class的数据结构，并且会完全copy 父class的值。这样父class在继承的子class有自己的副本，可以被子class 自定义修改，从而实现多态。

![[QOM_edu_class.svg]]

书<sup>1</sup>中的图片也很不错，我们贴过来:

![[Excalidraw/PCIDeviceClass层级结构]]
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

`InterfaceClass`和`ObjectClass`一样，作为基类存在. 

`interface`和`class`不同，如果有class继承了interface，需要实现interface中的接口。并且，在用户态API中，我们可以直接在`TypeInfo.Interfaces[]`中直接定义要继承的interface，而无需定义继承后的interface的type, 所以在实现流程中，会给interface自动分配名字，并构造`TypeInfo`.

名字的命名方式为`继承者TypeName::interface typename`, 如下图所示:

![[QOM-interface-type-info.svg]]

构造`TypeInfo` 是为了创建`TypeImpl`为创建 `InterfaceClass`做准备
![[QOM-interface-class.svg]]

上图主要是展示了，"conventional-pci-device", 这个interface和`edu` class的关系,  但是edu class如果继承的父类中有interface呢，则如下图所示，子类会创建`type name::interface name`的class( `edu: :vmstate_if_info`)，该`class(edu)`父类为其父类`(pci-device)` 相关interface(`pci-device: :vmstate_if_info`)的子类.

![[QOM-interface-class2.drawio.svg]]

**那也就是说，让子类继承父类时, 也会继承其接口**

> NOTE
> 
> 当子类，父类`TypeInfo.interfaces[]`都包含了相同的`interface type name`, 那子类创建的interface的名称该怎么命令呢？目前的代码实现是，命名为父类interface的名称.

### 总结

我们对上面数据结构知识做下总结:
*  API 侧提供了用户友好的API 数据结构:`TypeInfo`, `InterfaceInfo`, 这两个数据结构在API implment 相关数据结构中，并未引用.
* QOM class 是如何实现多态, 很简单，每个class中都包含父class的实体，这样为当前class定制父class的内容
* `TypeImpl`, `InterfaceImpl` 内容基本是COPY `XxxInfo`, 但是`TypeImpl`会通过指针引用其他`parent TypeImpl`, 从而串联继承关系，但是`InterfaceImpl`却只包含了一个字符串类型，因为其可以借助`TypeImpl`来串联进程关系。
* `TypeInfo`对`interface`继承只需要将所要继承的interface type name 传入即可，不用为继承后的interface type name 起名字，实现代码会自动生成
* interface会根据子类的继承关系，从而构建interface的继承关系
## QOM implment -- function

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
关于`type_init()`接口，和 QEMU model 实现相关，在 [[QEMU module]] 一文中讲述。这里我们只需要记住，这里定义的`do_qemu_init_xxxx()`将会在qemu 进程启动时，在`main()` 调用之前执行, 一些流程，将注册的`do_qemu_init_xxxx()`相关callback串到一组链表上，然后在main()函数执行早期会调用相关回调, 我们接下来看回调的具体内容，以`edu`为例:

```sh
type_register_static_array
=> foreach typeinfo
   ## 对每一个typeinfo 调用
   => type_register_static()
      ## 每一个要注册的类型都要有父类型，基类为ObjectClass
      => assert(info->parent)
         => type_register_internal()
            => ti:TypeImpl = type_new(info)
                => copy TypeInfo --> TypeImpl
                => ti->name = g_strdup(info->name)
                ...
            => type_table_add(ti)
               ## 以TypeImpl->name 加入hash表
               => g_hash_table_insert(type_table_get(), ti->name, ti)
```


那可以看到，`main()`执行早期, 已经将代码所有注册的`TypeInfo`转换为`TypeImpl`并添加进hash表，但是未搞两个事情:
* `TypeImpl` 的继承关系未串联
* 每个类型的interface 还未初始化, `TypeInfo.interfaces[]` 还未创建相关的`TypeImpl`

**类型的注册是为了后续类型初始化做准备** -- 类型的注册为所有类型准备好了模版，里面包含了初始化类型所需要的所有信息。
### type_initialize

`type_initialize()` 是类型初始化的入口函数，调用方分为两种:
* 创建instance(object)时，lazy create
* 调用`module_object_class_by_name()`， 只初始化class

前面提到过，`class` 相当于整个类型的const 部分，我们也可以称为公共部分，是该类型特征共有的不会更改的一些属性。所以，关于某个类型的初始化，每个类型在qemu启动后，只需要做一次

#### type_initlialize() part1 -- class size

```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/qemu/v11.0.0/qom/object.c"
LINES: "336-342"
TITLE: "type_initialize()"
```


当本次初始化流程中，发现未初始化class，会为class 申请空间并初始化.

```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/qemu/v11.0.0/qom/object.c"
LINES: "336-337,344,361"
TITLE: ""
```

但是某些`Type` 在定义`TypeInfo`时，并未指定`class_size`成员，这样的类型会通过获取父类的`class_size`作为该类的`class_size`:

```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/qemu/v11.0.0/qom/object.c"
LINES: "243-254"
TITLE: "type_class_get_size"
```

在回到 `type_initialize()`

#### type_initlialize() part2 -- copy parent class

```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/qemu/v11.0.0/qom/object.c"
LINES: "336,337,361-372"
TITLE: ""
```

申请完, class的空间后，接下来要根据`parent`(父类型), 来初始化当前type. 首先调用`type_initialize(parent)`, 确保父类型初始化完整，接下来将 <font color=red size=4>将父类型copy到子类型</font>(父类型class 为子类型class的第一个成员，例如`PCIDeviceClass`)

```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/qemu/v11.0.0/include/hw/pci/pci_device.h"
LINES: "26-27"
TITLE: "PCIDeviceClass"
```

另外, `interfaces`部分，不能全部copy 父类的。前面提到过，如果子类继承父类的interfaces, 其typename， 会修改为`子类名::interface typename`, 并且子类的interfaces 是父类interfaces的子类。（这些interfaces 也会构造继承关系，并通过子类 interfaces copy 父类interfaces，从而继承父类interfaces 方法)

好，我们来看下这部分流程:
#### type_initialize() part3 -- copy parent interface

```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/qemu/v11.0.0/qom/object.c"
LINES: "336-337,372-379"
TITLE: "type_initialize"
```

该流程会遍历父类`interface`，并通过`type_initialize_interface()`构造子类`interfaces`:

```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/qemu/v11.0.0/qom/object.c"
LINES: "300-319"
TITLE: "type_initialize_interface()"
```

该流程首先会构造一个`TypeInfo`, 然后将 **info.name** 修改为`typename::interface_name`, 并通过`type_new()`创建`iface_impl`, <font color="red">将parent_type设置为父类interfaces 的type</font> 另外通过 `type_initialize()`, 初始化子类`interface`, 并将其连接到子类 `ti->class->interfaces` 链表上

上面是copy 父类类型 `interfaces` 代码，而 如果是当前type中定义的interfaces呢? 在下面流程中处理:

```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/qemu/v11.0.0/qom/object.c"
LINES: "336-337,381-402"
TITLE: ""
```

流程和前面类似，不过其会额外通过`type_is_ancestor()`查找，当前类型`TypeInfo.interfaces[]`定义的interfaces 是否和父类中定义的一样。（方法是通过找不带任何前缀的interface name的类型，然后判断该类型是否为某个父类interfaces的 父类（或者爷爷interface，祖宗interface, 总是是有继承关系), 如果有，则没有必要在重新定义一个重复的。直接用父类的即可。

如果没有，则会根据刚刚说的祖宗interface 作为其父类，建立继承关系。为了方便起见，我们还是补一张图:

![[Excalidraw/interface_class_inherit.excalidraw]]

#### type_initialize() -- part4 init properties

```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/qemu/v11.0.0/qom/object.c"
LINES: "336-337,404-406"
TITLE: "type_initialize() properties"
```

我们在下面的章节详细讲解 `properties`。

#### type_initialize() part5 -- call class_init()

```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/qemu/v11.0.0/qom/object.c"
LINES: "336-337,407-419"
TITLE: "type_initialize() properties"
```


首先调用父类的`class_base_init()`, 初始化父类`class`部分。

`class_base_init()`注释如下:

```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/qemu/v11.0.0/include/qom/object.h"
LINES: "465-468"
TITLE: "class_base_init"
```

大概的意思是，在调用`class_init()`之前应该先调用`parent_class->class_base_init()`方法，因为父类部分成员不能直接从父类memory，需要做额外的初始化动作。

然后调用 `ti->class_init()`, 我们以`edu` 为例看下`class_init()`的大概流程:

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

因为`edu` 这里 初始化 其父类，`PCIDeviceClass` 和 父类的父类 `DeviceClass` 的部分成员。

下面展示`DEVICE_CLASS`宏, 我们看下如果通过当前的 `ObjectClass`，找到相应的父类

DEVICE_CLASS 展开, 以edu为例, `edu` 没有自定义`class`，而是使用的`PCIDeviceClass`:

```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/qemu/v11.0.0/include/hw/pci/pci_device.h"
LINES: "9-12"
TITLE: "DECLARE_OBJ_CHECKERS"
```

`DECLARE_OBJ_CHECKERS()`定义如下:

```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/qemu/v11.0.0/include/qom/object.h"
LINES: "215-218"
TITLE: "DECLARE_OBJ_CHECKERS"
```

分别声明了 `INSTANCE` 和 `CLASS`, 我们这里以`class`为例:

```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/qemu/v11.0.0/include/qom/object.h"
LINES: "193-200"
TITLE: "DECLARE_CLASS_CHECKERS"
```

* `OBJ_NAME##_GET_CLASS()`: 是**通过 `instance_obj` ** 获取该class
* `OBJ_NAME##_CLASS()`: 是 **通过基类** 获取该class

> NOTE
> 
> 至于`OBJECT_CLASS_CHECK()`, `OBJECT_GET_CLASS()`这部分细节，我们在附录展开

## object 初始化
现在注册好了类型，如果我们在qemu命令行执行`-device edu`, qemu则会使用前面定义好的类型来创建一个object, object作为实例，其继承自基对象`Object`, 前面提到过`Object`数据结构不仅包含了对生命周期管理的成员和方法，也有指向class的指针。这样一个完整的仿`C++`面向对象的object就被构造出来.

对象初始化的结构为`object_new()`, 以`edu`为例，在下面的流程中，会执行对该edu device的初始化:
```
main
 qemu_init
  qmp_x_exit_preconfig
   qemu_create_cli_devices
    qemu_opts_foreach
     device_init_func
       qdev_device_add
         qdict = qemu_opts_to_qdict
         qdev_device_add_from_qdict
```

简单看下`device_init_func`流程
```sh
# opts 和字典相关，
qdev_device_add_from_qdict(QDict *opts, ...)        
# 通过opts查询 driver, 返回"edu"
=> driver = qdict_get_try_str(opts, "driver")      
# 通过"edu"找到其class， 转换为DeviceClass
=> qdev_get_device_class(&driver, errp)   
# 找到bus, 为后续的qdev_realize做准备
=> path = qdict_get_try_str(opts, "bus");
###
### 关键点: 通过qdev_new()创建实例
###
=> dev = qdev_new(driver);
   => ObjectClass *oc = object_class_by_name(edu)  # 找到edu 的class
   => return DEVICE(object_new(name));    # 调用object_new , 然后强转为DeviceState实例
=> dev->opts = qdict_clone_shallow(opts);
=> object_set_properties_from_keyval()
###
### 关键点: 初始化实例
###
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

上面有两个关键流程:
* 通过`qdev_new()`创建实例对象
* 通过`qdev_realize()` 初始化实例对象

而关于

我们主要看下`object_new`

### object_new()

object new 流程：
```sh
object_new
=> ti = type_get_or_load_by_name(typename)        # 通过typename，找到TypeImpl
=> object_new_with_type(Type type:ti)
   # 如果该type没有初始化过，在这里初始化
   ## ====(1)====
   => type_initialize(type)               
   => alloc object instance 
      {
         size = type->instance_size;
         align = type->instance_align;
         ## 这里会根据align_size的大小，选择是否对其分配，下面我们展开代码:
         obj = g_malloc() / qemu_memalign
		 obj_free = g_free / qemu_vfree
      }
   => object_initialize_with_type(obj, size, type)
      => memset(obj, 0, type->instance_size);
      ## 初始化object class
      => obj->class = type->class;
      => object_ref(obj)                  # org refcount
      => object_class_property_init_all(obj)  #和properties相关
      => obj->properties = g_hash_table_new_full()
      ## ====(2)====
      => object_init_with_type(obj, type);
      => object_post_init_with_type()
         => 递归， 对其 obj 以及parent调用 ti->instance_post_init()
```

1. 前面提到过对于`type(class)`的初始化是`LAZY`的，qemu启动后，该type创建object时会通过`type_initialize()`初始化`class`
2.  前面提到过，class的继承是通过copy parent class来做到，并通过`class_base_init`对其parent class做一些简单的微调，而instance初始化也类似，通过递归对obj以及parent 都调用 `ti->instance_init()`，并通过递归对其obj以及parent 调用`ti->instance_post_init()`。但是class和instance有一点不同的是，class 是通过`copy` ， 而instance不行。因为`class` 定义类似于const，而instance则是每个实体都可能不一样。

> 这里需要注意的是, `object_init_with_type()`, 调用`ti->instance_init()`时，需要
> 先对父类进行init，再对子类， 而`object_post_init_with_type()`则相反。

看下`pci_edu_realize`

###  dc->realize()

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

QOM为了便于管理对象，为每个class定义了properties, `properties`的作用更像是,  为class 相当于有一些属性(成员)，这些属性的需求比较简单，是固定的`get`, `set`等等常规方法。

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

我们借鉴<sup>1</sup>中的图片:

![[Excalidraw/qemu_object_class_property.excalidraw]]


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
   => object_class_property_add()
      => prop->get = get
      => prop->set = set
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

关于属性部分，我们留个很大的尾巴，等之后有时间再看

#TODO 

# 附录

## gcc constructor attribute test
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

## OBJECT_CLASS_CHECK() && OBJECT_GET_CLASS()

```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/qemu/v11.0.0/include/qom/object.h"
LINES: "534,540-547,548,554-559"
TITLE: "OBJECT_CLASS_CHECK"
```

`OBJECT_GET_CLASS()` 用来比对instance `obj`所在的class和`name`所代表的class是否相同。并强转为`class` 类型

而`OBJECT_CLASS_CHECK()`的作用是对比`class` 和`name` 所代表的class是否一致。并强转为`class_type`类型

`object_class_dynamic_cast_assert`定义如下:

```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/qemu/v11.0.0/qom/object.c"
LINES: "991-995,1015-1021"
TITLE: "object_class_dynamic_cast_assert"
```

`object_class_dynamic_cast()`定义如下:

```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/qemu/v11.0.0/qom/object.c"
LINES: "943-989"
TITLE: "object_class_dynamic_cast()"
COMMENTS:
  956: |-
    对比class->type和 typename是否相同，如果相同直接返回
  960:
    如果不一样，找到其typename所对应的type.
  984: |-
    如果 type->class 有 interfaces，并且 target_type也是interfaces, 这时候，
    我们应该找到该类型interfaces，去对比interfaces 和target_type之间是否是继承关系,
    如果target_type时 target_class(interfaces)的父类，则返回target_class
    (子类包含父类)
  966: |-
    和上面类似，只不过这里不再对比interfaces，而是直接对比这两个类(class 和 typename)是
    否存在 typename时class的父类，这种关系
```


# 参考文献

[1]. <<QEMU-KVM 源码解析与应用>>
[2]. [deepseek QOM properties](https://chat.deepseek.com/share/sc7l7ltxq3per0cttv)