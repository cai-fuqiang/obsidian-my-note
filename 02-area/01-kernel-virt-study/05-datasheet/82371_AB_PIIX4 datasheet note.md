## 7.2. Power Management IO Space Registers

### 7.2.1. PMSTS—POWER MANAGEMENT STATUS REGISTER (IO)

> [!PDF|note] [[82371_AB_PIIX4.pdf#page=137&selection=10,0,12,43&color=note|82371_AB_PIIX4, p.137]]
> > 7.2.1. PMSTS—POWER MANAGEMENT STATUS REGISTER (IO)
> 
> 该寄存器 用来查询哪些 event 是 pending 的

> [!PDF|note] [[82371_AB_PIIX4.pdf#page=137&selection=42,0,43,1&color=note|82371_AB_PIIX4, p.137]]
> > Power Button Override Status (PWRBTNOR_STS)—R/WC.
> 
> `PWRBIN#` 保持高电平4s后，拉低该引脚电平，并且clear `PWRBIN_STS` bit, 设置该位

> [!PDF|note] [[82371_AB_PIIX4.pdf#page=137&selection=63,0,63,37&color=note|82371_AB_PIIX4, p.137]]
> > Power Button Status (PWRBTN_STS)—R/WC
> 
> 按电源键之前，`PWRBTN#` 引脚为**高电平**, 按住电源键时，`PWRBTN#` 变为低电平, 而PM Device检测到为
> 低电平后，先等16ms，如果16ms 后，仍然为低电平，则将该寄存器bit置为1, 如果低电平保持超过4s，则
> 将该bit clear，and set `PWRBINOR_STS` bit
> 
> 另外, 
> * `PMEN.bit[8](Power Button Enable (PWRBTN_EN)—R/W.)` 可以配置当设置该bit时，是否产生`SMI#`或者`SCI`
> * `PMCNTRL.SCL_Enable`: 控制 `PWRBIN_STS`在内的很多事件，是否产生`SCI`中断

> [!PDF|note] [[82371_AB_PIIX4.pdf#page=137&selection=109,0,110,1&color=note|82371_AB_PIIX4, p.137]]
> > Timer Overflow Status (TMROF_STS)—R/WC.
> 
> PM 有个timer的组件，该bit为1 表示timer 到期
### 7.2.2. PMEN—POWER MANAGEMENT RESUME ENABLE REGISTER (IO)

> [!PDF|note] [[82371_AB_PIIX4.pdf#page=138&selection=4,0,8,4&color=note|82371_AB_PIIX4, p.138]]
> > 7.2.2. PMEN—POWER MANAGEMENT RESUME ENABLE REGISTER (IO)
> 
> 该寄存器用来控制 resume event 是否开启


> [!PDF|note] [[82371_AB_PIIX4.pdf#page=138&selection=42,0,43,1&color=note|82371_AB_PIIX4, p.138]]
> > Power Button Enable (PWRBTN_EN)—R/W.
> 
> 需要注意，当设置为0时，按住电源键 `PWRBIT#` 引脚仍然会被拉起，并且`PMRSTS.PWRBIT_STS` bit 仍然会被设置，只不过不会产生 `SCI` or `SMI#`

> [!PDF|note] [[82371_AB_PIIX4.pdf#page=138&selection=65,0,66,1&color=note|82371_AB_PIIX4, p.138]]
> > Power Management Timer (TMROF_EN)—R/W.
> 
> 控制pmtimer到期时是否设置`TMROF_STS` bit && 产生SCI 中断

### 7.2.3. PMCNTRL—POWER MANAGEMENT CONTROL REGISTER (IO)

> [!PDF|note] [[82371_AB_PIIX4.pdf#page=139&selection=28,0,30,56&color=note|82371_AB_PIIX4, p.139]]
> > SCI Enable (SCI_EN)—R/W. 
> 
> 该bit用来控制下面事件是否产生SCI中断
> * PWRBTN_STS(目前我们仅关注这个)
> * ....


### 7.2.4. PMTMR—POWER MANAGEMENT TIMER REGISTER (IO)

> [!PDF|note] [[82371_AB_PIIX4.pdf#page=139&selection=56,7,56,67&color=note|82371_AB_PIIX4, p.139]]
> > This is a 24-bit counter that runs off a 3.579545-MHz clock.
> 
> timer 为固定周期

> [!PDF|note] [[82371_AB_PIIX4.pdf#page=139&selection=56,67,58,20&color=note|82371_AB_PIIX4, p.139]]
> >  The timer is reset to an initial value of 0 during a PCI reset, and then continues counting unless the 14.31818-MHz OSC input to the chip is stopped.
> 
> timer依赖 14.31818 时钟。对该时钟进行4分频，所以如果时钟停止向chip发送信号，则timer停止工作


> [!PDF|note] [[82371_AB_PIIX4.pdf#page=139&selection=59,32,60,32&color=note|82371_AB_PIIX4, p.139]]
> > When bit 23 of the timer transitions from high-to-low or low-tohigh, the TMROF_STS bit is set. 
> 
> 可以理解为 23bit最高位反转时，触发 Timer event. 这样可以保证时钟中断在软件不干预计数器的情况下, 阶段性触发。
> 例如从0到24bit全F需要4s，那么时钟中断则2s触发一次