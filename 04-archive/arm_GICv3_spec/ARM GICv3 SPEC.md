# 3. GICv3 fundamentals

## 3.1 Interrupt types

> [!PDF|yellow] [[GICv3_Software_Overview_Official_Release_B.pdf#page=9&selection=26,0,26,16&color=yellow|GICv3_Software_Overview_Official_Release_B, p.9]]
> > Interrupts types
> 
> 一共有四种中断类型:
> 首先分为两类XPI, SGI
> * XPI: 外围中断，发起这是从downstream->interrupt controller->CPU
> 	* SPI: shared(共享的那个设备都可以用)
> 	* PPI: Private(专有设备使用(关系户）)
> 	* LPI: locality-specific
> * SGI: inter-processor communication
> 其中LPI需要特别关注下, 这个是为MSI专门设计的(虽然SGI可能用于MSI)。但是其路由方式很不一样，其直接路由到Redistributors, 然后在由Redistributors 触发具体vector的中断. 而SGI还是需要Distributor 路由。
> 这个就像IOAPIC和LAPIC一样。

|         | Distributor | IOAPIC |
| ------- | ----------- | ------ |
| 路由的中断类型 | signal, MSI | signal |
| 是否全局唯一  | Y           | Y      |

||Redistributors||

单词翻译
> [!PDF|translate] [[GICv3_Software_Overview_Official_Release_B.pdf#page=9&selection=21,78,21,87&color=translate|GICv3_Software_Overview_Official_Release_B, p.9]]
> > compliant
>
> /kəmˈplīənt/
> 合规

> [!PDF|translate] [[GICv3_Software_Overview_Official_Release_B.pdf#page=9&selection=30,12,30,22&color=translate|GICv3_Software_Overview_Official_Release_B, p.9]]
> > Peripheral
> 
> 外围

### 3.1.2 Interrupt Identifiers

> [!PDF|yellow] [[GICv3_Software_Overview_Official_Release_B.pdf#page=9&selection=60,0,62,20&color=yellow|GICv3_Software_Overview_Official_Release_B, p.9]]
> > 3.1.2 Interrupt Identifier
> 
>每个 interrupt source 被标识为 一个ID number (INTID), INTID被分为不同的range, 每个range分配给一种特定类型的中断（上面讲的三种类型)

### 3.1.3 How interrupts are signaled to the interrupt controller

> [!PDF|yellow] [[GICv3_Software_Overview_Official_Release_B.pdf#page=10&selection=13,0,15,55&color=yellow|GICv3_Software_Overview_Official_Release_B, p.10]]
> > 3.1.3 How interrupts are signaled to the interrupt controller
> 
> 本节讲述了中断 signal interrupt controller的两种方式:
> * signal
> * message-based

> [!PDF|important] [[GICv3_Software_Overview_Official_Release_B.pdf#page=10&selection=17,93,17,102&color=important|GICv3_Software_Overview_Official_Release_B, p.10]]
> > dedicated
> 
> 这个就是signal 缺点，专用信号就意味扩展性差。
> [deepseek解释](https://chat.deepseek.com/share/mjvnr5j13xwg4zgfat)

> [!PDF|important] [[GICv3_Software_Overview_Official_Release_B.pdf#page=10&selection=22,80,23,102&color=important|GICv3_Software_Overview_Official_Release_B, p.10]]
> >  message-based interrupt is an interrupt that is set and cleared by a write to a register in the interrupt controller
> 
> 这是message-based的好处，message-based是指对interrupt的一个寄存器的写操作。写的内容表示中断的特定信息。无需复杂的硬件电路扩展
> 从这两个图中可以看出，interrupt signal 使用的是专用线（不使用interconnect），而interrupt message 直接使用interconnect。这也就说明`Peripheral`访问upstream资源中断和其他访问使用的是一套协议。（如果是PCIe协议，MSI就是一个posted memory write，只不过message address 是interrupt controller的地址)

> [!PDF|yellow] [[GICv3_Software_Overview_Official_Release_B.pdf#page=10&selection=27,0,27,5&color=yellow|GICv3_Software_Overview_Official_Release_B, p.10]]
> > Using
> 
> 这段讲解了message-based interrupt 的优点。适用于大型系统成百上千中断的中断源。

> [!PDF|yellow] [[GICv3_Software_Overview_Official_Release_B.pdf#page=10&selection=71,0,71,46&color=yellow|GICv3_Software_Overview_Official_Release_B, p.10]]
> > Impact of message-based interrupts on software
> 
> 这段讲解了message-based interrupt 对于软件适配上的影响。
> 结论是影响非常小。
> 一个比较大的改动是配置外围设备。例如需要配置外围设备告诉他interrupt controller的地址。

> [!PDF|translate] [[GICv3_Software_Overview_Official_Release_B.pdf#page=10&selection=20,9,20,18&color=translate|GICv3_Software_Overview_Official_Release_B, p.10]]
> > Dedicated
> 
> 专用的a

## 3.2 Interrupt state machine


> [!PDF|todo] [[GICv3_Software_Overview_Official_Release_B.pdf#page=11&selection=45,0,46,4&color=todo|GICv3_Software_Overview_Official_Release_B, p.11]]
> > NOTE: LPIs do not have an active or active and pending state. For more information, see section 6.2.
> 
> 需要后续看下为什么LPI 没有active 和 active and pending state

### 3.2.1 Level sensitive

> [!PDF|note] [[GICv3_Software_Overview_Official_Release_B.pdf#page=12&selection=30,0,39,90&color=note|GICv3_Software_Overview_Official_Release_B, p.12]]
> > The interrupt transitions from pending to active and pending when a PE acknowledges the interrupt by reading one of the IARs (Interrupt Acknowledge Registers) in the CPU interfac
> 
> pending -> active and pending 通过 PE 去读 IARs来ACK 这个interrupt

> [!PDF|important] [[GICv3_Software_Overview_Official_Release_B.pdf#page=12&selection=43,0,43,62&color=important|GICv3_Software_Overview_Official_Release_B, p.12]]
> > At this point the GIC deasserts the interrupt signal to the PE
> 
> 这时，GIC 会deassert PE的interrupt signal。这里我并没有相同为什么非要在变active && pending 的时候dessert，而不能放在active and pending-> active 的时候。

> [!PDF|note] [[GICv3_Software_Overview_Official_Release_B.pdf#page=12&selection=45,0,45,28&&color=note|GICv3_Software_Overview_Official_Release_B, p.12]]
> > Active and Pending to Active
> 
> 发生在外围设备de-assert,通常也是驱动程序通知外围设备的（通过写外围设备寄存器)

> [!PDF|note] [[GICv3_Software_Overview_Official_Release_B.pdf#page=12&selection=59,0,59,18&color=note|GICv3_Software_Overview_Official_Release_B, p.12]]
> > Active to Inactive
> 
> 写EIOR。这时候表示PE完成了这个中断的处理


单词翻译

> [!PDF|translate] [[GICv3_Software_Overview_Official_Release_B.pdf#page=11&selection=78,6,78,15&color=translate|GICv3_Software_Overview_Official_Release_B, p.11]]
> > sensitive
> 
> 敏感

> [!PDF|translate] [[GICv3_Software_Overview_Official_Release_B.pdf#page=12&selection=26,0,26,10&color=translate|GICv3_Software_Overview_Official_Release_B, p.12]]
> > sufficient
> 
> 充足的

### 3.2.2 Edge-triggered

> [!PDF|important] [[GICv3_Software_Overview_Official_Release_B.pdf#page=12&selection=94,0,94,19&color=important|GICv3_Software_Overview_Official_Release_B, p.12]]
> > Inactive to Pending
> 
> 和上面一样，不过peripheral 只是拉一下电平，很快就dessert
> 

> [!PDF|note] [[GICv3_Software_Overview_Official_Release_B.pdf#page=12&selection=109,0,109,17&color=note|GICv3_Software_Overview_Official_Release_B, p.12]]
> > Pending to Active
> 
> same

> [!PDF|important] [[GICv3_Software_Overview_Official_Release_B.pdf#page=12&selection=125,0,125,28&color=important|GICv3_Software_Overview_Official_Release_B, p.12]]
> > Active to Active and Pending
> 
> 和上面不同的是，边缘触发不会一直pending，所以active and pending 出现时，一定是又有新的interrupt 被触发

> [!PDF|note] [[GICv3_Software_Overview_Official_Release_B.pdf#page=13&selection=13,0,13,28&color=note|GICv3_Software_Overview_Official_Release_B, p.13]]
> > Active and Pending to Pending
> 
> 这个没啥说的, 说明被写EOIRs时，有pending的中断还未处理.

## 3.3 Affinity routing

> [!PDF|note] [[GICv3_Software_Overview_Official_Release_B.pdf#page=13&selection=29,0,31,16&color=note|GICv3_Software_Overview_Official_Release_B, p.13]]
> > 3.3 Affinity routing
> 
> 这个可扩展性太好了

> [!PDF|todo] [[GICv3_Software_Overview_Official_Release_B.pdf#page=13&selection=50,0,50,20&color=todo|GICv3_Software_Overview_Official_Release_B, p.13]]
> > The affinity scheme 
> 
> 这里面涉及的两个寄存器 MPIDR, GICR_TYPER得看下



单词翻译:

> [!PDF|translate] [[GICv3_Software_Overview_Official_Release_B.pdf#page=13&selection=58,0,58,9&color=translate|GICv3_Software_Overview_Official_Release_B, p.13]]
> > identical
> 
> 完全相同的


> [!PDF|translate] [[GICv3_Software_Overview_Official_Release_B.pdf#page=14&selection=22,82,22,90&color=translate|GICv3_Software_Overview_Official_Release_B, p.14]]
> > practice
> 
> 实践


## 3.5 Programmers' model

> [!PDF|yellow] [[GICv3_Software_Overview_Official_Release_B.pdf#page=16&selection=35,0,39,4&color=yellow|GICv3_Software_Overview_Official_Release_B, p.16]]
> > 3.5 Programmers’ model
> 
> 本段主要讲书了三种类型的接口，分别对应中断控制器的三组组件:
> * Distributor(`GICD_*`)
> * Redistributor(`GICR_*`)
> * CPU Interface(`ICC_*_ELn`)

> [!PDF|yellow] [[GICv3_Software_Overview_Official_Release_B.pdf#page=16&selection=57,0,59,1&color=yellow|GICv3_Software_Overview_Official_Release_B, p.16]]
> > Distributor (GICD_*
> 
> * 管理配置SPI，类似于一个重定向的功能(另外Distributor不会管理PPIs，那也就是说PPIs是直接到Redistributors)

> [!PDF|note] [[GICv3_Software_Overview_Official_Release_B.pdf#page=16&selection=86,0,86,29&color=note|GICv3_Software_Overview_Official_Release_B, p.16]]
> > Generating message-based SPIs
> 
> OH?, 将signal 转换为 MSI?

> [!PDF|yellow] [[GICv3_Software_Overview_Official_Release_B.pdf#page=17&selection=13,0,15,1&color=yellow|GICv3_Software_Overview_Official_Release_B, p.17]]
> > Redistributors (GICR_*
> 
> 类似于LAPIC的工作，这里面包含对SGIs和 PPIs的处理

> [!PDF|important] [[GICv3_Software_Overview_Official_Release_B.pdf#page=17&selection=42,0,43,48&color=important|GICv3_Software_Overview_Official_Release_B, p.17]]
> > Base address control for the data structures in memory that support the associated interrupt properties and pending state for LPIs.
> 
> 这个很关键, LPIs 相关的中断优先级和 pending state 是从内存中维护的。

> [!PDF|important] [[GICv3_Software_Overview_Official_Release_B.pdf#page=17&selection=47,0,47,45&color=important|GICv3_Software_Overview_Official_Release_B, p.17]]
> > Power management support for the connected PE
> 
> 这个同样也很关键。其负责 其连接的PE的电源管理(跟LAPIC很像)

> [!PDF|yellow] [[GICv3_Software_Overview_Official_Release_B.pdf#page=17&selection=49,0,51,1&color=yellow|GICv3_Software_Overview_Official_Release_B, p.17]]
> > CPU interfaces (`ICC_*_ELn`
> 
> 这个就像是x86中的core部分的接口，例如`CR8`,`TPR`

## 5.3 Spurious Interrupt

单词翻译:

> [!PDF|translate] [[GICv3_Software_Overview_Official_Release_B.pdf#page=22&selection=15,0,15,8&color=translate|GICv3_Software_Overview_Official_Release_B, p.22]]
> > Spurious
> 
> 虚假的
# 6. Configuring LPIs

> [!PDF|note] [[GICv3_Software_Overview_Official_Release_B.pdf#page=28&selection=28,19,28,48&color=note|GICv3_Software_Overview_Official_Release_B, p.28]]
> > Interrupt Translation Service
> 
> 类似于 VT-D(iommu)的中断重定向



单词翻译:

> [!PDF|translate] [[GICv3_Software_Overview_Official_Release_B.pdf#page=28&selection=33,65,33,76&color=translate|GICv3_Software_Overview_Official_Release_B, p.28]]
> > appropriate
> 
> 合适的

> [!PDF|translate] [[GICv3_Software_Overview_Official_Release_B.pdf#page=28&selection=34,82,34,94&color=translate|GICv3_Software_Overview_Official_Release_B, p.28]]
> > individually
> 
> 单独的


> [!PDF|translate] [[GICv3_Software_Overview_Official_Release_B.pdf#page=28&selection=37,39,37,48&color=translate|GICv3_Software_Overview_Official_Release_B, p.28]]
> > efficient
> 
> 高效的


## 6.1 LTS
### 6.1.1 Operation of an ITS

> [!PDF|note] [[GICv3_Software_Overview_Official_Release_B.pdf#page=28&selection=90,0,94,29&color=note|GICv3_Software_Overview_Official_Release_B, p.28]]
> > The ITS translates the EventID that is written to GITS_TRANSLATER by the peripheral to an INTID
> 
> 外围设备写`GITS_TRANSLATER` EventID, ITS负责将其转换为对某个 PE 的 INITID

> [!PDF|note] [[GICv3_Software_Overview_Official_Release_B.pdf#page=28&selection=98,0,101,2&color=note|GICv3_Software_Overview_Official_Release_B, p.28]]
> > LPI INTIDs are grouped together in collections. 
> 
> 把某些 LPI INITIDs 划分为一个组，称为collections，每个collections 会被路由到同一个
> `Redistributor`.
> 这个由软件管理，方便其在不同的PE之间移动interrupt。（这个对虚拟机很有用)

> [!PDF|yellow] [[GICv3_Software_Overview_Official_Release_B.pdf#page=28&selection=105,0,105,11&color=yellow|GICv3_Software_Overview_Official_Release_B, p.28]]
> > An ITS uses
> 
> * Device Tables: Map DeviceIDs to Interrrupt Translation Table(ITT)
> * Interrupt Translation Tables: 决定某个DeviceID的设备EventID和INITID之前的映射关系。
> * Collection Table: 映射collectoins 到 Redistributors



# 7. Sending and receiving SGIs
> [!PDF|important] [[GICv3_Software_Overview_Official_Release_B.pdf#page=38&selection=26,0,28,15&color=important|GICv3_Software_Overview_Official_Release_B, p.38]]
> > 7.1 Generating SGIs
> 
> 生成SGI

