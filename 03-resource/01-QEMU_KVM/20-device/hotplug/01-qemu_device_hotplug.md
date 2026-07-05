---
status: in-progress
show in nav: true
create date: 2026-06-30 21:44:42
complete date:
tags:
priority: 0
summary:
aliases:
  - PCI设备热插拔
---
<!--TOC-->
- [ ] [background](#background)
	- [ ] why hotplug
	- [ ] real world
	- [ ] vm world
- [ ] implement details
	- [ ] overflow
	- [ ] hotplug controller (SHPC/PCIe native)
	- [ ] struct
	- [ ] USERSPACE API
	- [ ] plug/unplug details
	- [ ] ACPI operation details
- [ ] code details
	- [ ] device_realize
	- [ ] qmp_device_add
	- [ ] qmp_device_del
	- [ ] OS call ACPI method `_EJ0`

# background

## hotplug challenges

hotplug 要解决的不是“设备能不能在运行时创建”这么简单，而是：**系统运行期间，硬件拓扑发生变化时，OS 如何安全地发现、初始化、停止和移除设备**。

对 OS 来说，一个设备不是凭空出现的。它必须挂在某条总线、某个 slot 或某个 firmware 描述的节点下面，并且经过一套可观察的状态变化：

- **presence**：slot 里是否有设备
- **power**：slot 是否给设备上电
- **event**：硬件或固件如何通知 OS “拓扑变了”
- **enumeration**：OS 如何重新扫描总线并绑定 driver
- **ejection**：OS 如何先停 driver、释放资源，再允许设备离开

所以 hotplug 的核心其实是一套协作协议：设备提供能力，bus/controller 暴露状态，firmware 描述入口，OS 负责最终的 probe/remove。QEMU 里的 `device_add` / `device_del` 也要遵守这套模型，否则 QEMU 内部创建了设备，Guest OS 仍然可能完全不知道。
## real world

物理机里，热插拔通常围绕 **slot** 展开。slot 是一个稳定的容器：设备可以来来去去，但 OS 看到的是 slot 的状态变化，而不是一个随机出现的 PCI function。

常见机制有三类：

| 机制                  | OS 看到的入口                                           | 事件来源                      | Linux driver                  |
| ------------------- | -------------------------------------------------- | ------------------------- | ----------------------------- |
| ACPI-based hotplug  | ACPI namespace 中的 device/slot                      | GPE + ACPI Notify         | `drivers/pci/hotplug/acpiphp` |
| SHPC                | PCI-to-PCI Bridge 上的标准 hotplug controller          | SHPC register / interrupt | `drivers/pci/hotplug/shpchp`  |
| PCIe native hotplug | PCIe Root Port / Downstream Port 的 slot capability | Slot Status / interrupt   | `drivers/pci/hotplug/pciehp`  |

三者的底层形式不同，但概念是一致的：

1. controller/firmware 告诉 OS：slot 状态发生变化
2. OS 读取状态，判断是 insertion 还是 removal
3. insertion 时，OS 扫描 bus，分配资源，绑定 driver
4. removal 时，OS 先让 driver quiesce/remove，再切断设备可见性

## vm world

虚拟机没有真实的物理 slot，但 Guest OS 仍然按物理机模型工作。因此 QEMU 不能只把一个 `PCIDevice` 对象挂到内部 bus 上，还必须模拟出 Guest 能理解的 hotplug 入口。

可以把 VM hotplug 理解成三层：

1. **management plane**：用户或管理系统通过 QMP/HMP 发起 `device_add` / `device_del`
2. **QEMU device model**：QEMU 创建、realize、挂载或标记待删除设备
3. **guest-visible hotplug mechanism**：QEMU 通过 ACPI、SHPC 或 PCIe native hotplug 向 Guest 注入事件

QEMU 代码里 hotplug 比普通 device realize 更复杂的原因是其多了一些和Guest 交互的流程：**add 侧重“让 Guest 发现新设备”，del 侧重“等待 Guest 安全移除旧设备”**。而Guest 是如何"知道"怎么和ACPI Firmware(QEMU) 进行交互呢 -- **通过ACPI AML**。
***
本文以x86 pc机型为例，探索下PCI Device Hotplug 的细节
# implement details

## overflow

![[03-resource/01-QEMU_KVM/20-device/hotplug/excalidraw/device_hotplug_overview.excalidraw|700]]
1. 用户通过 qmp/hmp ==device_add,device_dell== 命令完成热插和热拔操作
2. 在热插拔过程中会涉及一些 ==qdev operation==
	* 在热插中qemu create qdev
	* 在热拔过程中qemu destroy qdev.
```ad-todo
qdev 的具体实现，不属于本文内容，请见 [Sorry 404]()
```
3. 热插拔功能是主板的行为，我们本文以pc 机型为例。PC 机型是模拟的real world 中的`Intel 82371AB` 芯片组。但其并没有完全参照该芯片组设计模拟，例如，热插拔功能，是Qemu 自行设计的。
4. Qemu "自研" 的 `PIIX3`改进版芯片组，Guest OS认识么？Guest OS难道要为了"`PIIX3` qemu改" 单独出一版驱动么？答案是否定的。通过Qemu将这些 "OPERATION" 封装到了 ACPI AML中。guest通过执行AML中的某些"代码"完成QEMU想让Guest 执行的操作。这更像是ACPI FIrmware(Qemu) 在Guest中的HOOK。
5. "PIIX3 Qemu改" 这个设备在QEMU中也是用QOM管理

***

接下来，我们展开上面几点做详细介绍。

## QEMU PIIX3 PM DEVICE

![[PIIX4_PmDevice.excalidraw|900]]
前面提到过，Qemu 仿真Intel PIIX3 芯片组的PM Device 作为pc 机型的PM Device。该PM Device 是一个PCI Device。其通过 IO Bar, 向软件侧提供操作端口。qemu模拟了部分
```ad-todo
这部分这里不做介绍, 在 [sorry 404]() 做介绍
```
并添加了 一些 "寄存器" 用作热插拔(PCI device, CPU 等) feature.
### GPE0
无论是CPU热插拔，还是设备热插拔，都依赖 GPE 来指示是否发生了`plug/unplug`事件, 以及具体的事件类型是啥(是CPU热插拔，还是PCI Device热插拔),  而GPE也只报告HOTPLUG 相关事件。而其他的事件，比如按关机按钮，PM Timer到期，则在其他的寄存器中报告。
### acpi-pci-hotplug register

关于pci hotplug相关的寄存器, **主要是==QEMU 用来向guest报告哪些设备发生了hotplug event==，guest 调用某些<mark style="background:#fdbfff">ACPI method</mark> ，以及==guest OS用来向Qemu报告ready to whole unplug== 的<mark style="background:#fdbfff"> ACPI `_EJ0` method</mark>, 所需要访问的寄存器.**

```ad-note
**看到guest 操作 这些register 都是通过ACPI method，==ACPI 向 Guest driver 屏蔽了这些操作register细节==**
```

具体寄存器如下:
* [[QEMU ACPI BIOS PCI hotplug interface#PCI slot injection notification pending (IO port 0xae00-0xae03, 4-byte access)|PCI slot injection notification pending]]: 用来标识哪个设备触发了plug event
* [[QEMU ACPI BIOS PCI hotplug interface#PCI slot removal notification (IO port 0xae04-0xae07, 4-byte access)|PCI slot removal notification]] :  用来标识哪个设备触发了unplug event
* [[QEMU ACPI BIOS PCI hotplug interface#PCI removability status (IO port 0xae0c-0xae0f, 4-byte access)|PCI removebility status]] : 这是一个描述slot 热插拔能力的reg ，用来表示哪些slot 可以进行热插拔
* [[QEMU ACPI BIOS PCI hotplug interface#PCI device eject (IO port 0xae08-0xae0b, 4-byte access)|PCI device eject]] : 
	* read: 读取eject时，也是一个cap reg，每个bit用来指示某个features，目前的值为0.
	* write: 用于 ACPI `_EJ0` method 使用，用于通知Qemu 哪些设备可以安全弹出

```ad-important
注意，前面四个, reg 都是per-bit a slots. **注意, 是 ==slot== , 我们知道如果能表明一个具体的PCI device的位置，<mark style="background:#d3f8b6">还需要bus信息</mark>, 而bus信息需要 <mark style="background:#d3f8b6">PCI bus select reg</mark> 指示哪些寄存器**
```
* **<mark style="background:#d3f8b6">PCI_bus_select</mark>**:  Guest driver 用来指定选择哪个bus进行后续操作

### acpi-evt, acpi-cnt, acpi-tmr

这些寄存器不做过多解释，详细情况见:

[[[[82371_AB_PIIX4.pdf#page=117&offset=0,726,0|INTEL 82371 spec -- PM register Descripions]]]]

## userspace interface
### device add

![[qmp_device_xxx.excalidraw#^group=R8lSfL55|qmp_device_add|600]]
1. 首先从 qdict <mark style="background:rgba(255, 183, 139, 0.55)">"driver"</mark> `DeviceClass` 为后续的`qdev_new()`做准备
2. 从qdict <mark style="background:rgba(255, 183, 139, 0.55)">"bus"</mark> 字段中找到具体的 Bus Type 实例(`BusState`) 为后续的`qdev_realize()`做准备
3. `qdev_new()`
4. `qdev_realize()`
    + 在`realize()` 过程中, 一个很重要的步骤是调用`HotplugHandler->plug()`函数，**该函数最终会设置"PM device"相关寄存器(用来指示是那个设备发生了==plug==)，并通过`SCI`通知Guest ACPI hotplug driver.**

---

我们展开看下`HotplugHandler->plug`的后续流程:

![[03-resource/01-QEMU_KVM/20-device/hotplug/excalidraw/device_plug_overview.excalidraw|800]]
在qemu调用 `plug_request()` 后，会做如下事情:
1. qemu 首先根据设备位置 (`[bus, slots]`) 选择该<mark style="background:rgba(255, 183, 139, 0.55)">bus</mark>对应的PCI slots injection notification <mark style="background:rgba(255, 183, 139, 0.55)">bitmaps</mark>，并且根据==slots==, 在上述 <mark style="background:rgba(255, 183, 139, 0.55)">bitmaps</mark> 中置为 相应==bit==(图中3)
2. 在置完bit of `injection notification pending bitmaps`之后,  需要通过 置位<mark style="background:rgba(255, 183, 139, 0.55)">GPE0.PCI</mark> 指示本次事件的类型 -- PCI device Hotplug event(图中4)
3. qemu发送 SCI 至guest
4. Guest driver 收到SCI，首先通过读 <mark style="background:rgba(255, 183, 139, 0.55)">GPE0</mark> 判断是什么事件(PCI device hotplug)，然后通过 write PCI bus select and read bitmaps, 来判断是是发生了plug还是unplug，并且触发事件的设备位置。类似于:
```
for bus in [0,255] {
  'PCI bus select reg' = bus
  for slot in [0,31] {
    if 'PCI slot injection notification pending'[slot] == 1; then NOTIFY(PLUG, [bus, slot])
    if 'PCI slot removal notification'[slot] == 1; then NOTIFY(UNPLUG, [bus, slot])
  }
}
```
5. 进行设备初始化
### device del
![[qmp_device_xxx.excalidraw#^group=N_kXanpHLsjAy0692kYJr|qmp_device_del|300]]
`device_del()`实现和 `device_add()` 类似，只不过`device_del()`是对已经存在的设备进行热拔并销毁。而在销毁之前，先调用`HotplugHander->unplug_request` , **设置"PM device"相关寄存器(用来指示是那个设备发生了==unplug==)，并通过`SCI`通知Guest ACPI hotplug driver.**

但是不同的是, 当发送完`SCI`后，`qmp_device_del()`函数返回，在返回时，qemu可能未对要unplug的pci device做任何操作。Guest OS 后续解除对设备占用，可以让底层移除设备，"通知" QEMU(`_EJ0`) 可以对彻底让该device "消失"时，Qemu才会对qdev 做destroy。

***
![[device_unplug_overview.excalidraw|900]]
unplug 的流程类似, 但是区别是`qmp_device_del()`在通过`SCI`通知到guest后，**其不会立即删除设备，因为需要等 guest driver 完全解除对设备的占用并释放后，Qemu再完成对设备的释放**，而QEMU 怎么知道呢? 通过 ACPI `_EJ0` method。该method 最终的目的是设置 对应设备位置的 <mark style="background:#b1ffff">PCI device eject</mark>。QEMU会捕获这个访问，并认为此时guest已经准备好"拔掉"设备, 此时才执行`qdev_unparent()`释放设备。

## qdev operation

```ad-todo
关于 qdev operation 的细节我们不再这里展开，详细见

[sorry 404]()
```
## ACPI operation

前面讲解的流程中涉及对 PM. 

![[guest_ACPI_driver_overflow.excalidraw|900]]
