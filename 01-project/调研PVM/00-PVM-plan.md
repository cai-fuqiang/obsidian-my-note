---
share_link: https://share.note.sx/qos4s091#L8qu6r2wIlv8ElDL3tzCow
share_updated: 2026-08-25T09:29:56+08:00
modified: 2026-09-17T10:51:47+08:00
---
* [x] 走读PVM论文  
   * [[01-project/调研PVM/01-PVM introduce|01-PVM introduce | 笔记链接]]
* [x] 简单测试PVM + qemu, 以及 PVM + cloud hypervisor
   *  [[11-archive/01-completed-project/调研PVM-new/02-0-PVM-practice|02-0-PVM-practice]]
* [x] 在虚拟机中测试PVM + 定制dragonball
   * [[05-0-PVM-with-private-Dragonball]]
* [ ] L1 + PVM/KVM vs L0 + PVM/KVM 性能对比测试 ➕ 2026-08-20 
	* [x] 在 host 中搭建 kvm + kata 环境 做对比测试 ➕ 2026-08-20 ✅ 2026-08-21
	* [ ] 性能测试  [[06-性能测试项]] ⏫ 
* [ ] 代码走读计划
	* [ ] switcher 
		* [x] switcher memory map 🛫 2026-08-24 ⏳ 2026-08-26 📅 2026-08-27 ✅ 2026-08-31(但是未整理)
		* [ ] cr3 switch 🛫 2026-08-26 ⏳ 2026-08-26 📅 2026-08-28
			* [ ] asid assignment 🛫 2026-08-31 ⏳ 2026-08-31 📅 2026-09-01 
		* [ ] handle syscall (including fast path)  🔽 
		* [ ] handle exception
		* [ ] handle event
* [ ] 性能调优
	* [ ] 调试PAGE FAULT
		* [x] 🛫 2026-09-04 ⏳ 2026-09-04 📅 2026-09-05 重新编写Page Fault microbench来验证PVM的优势 ✅ 2026-09-14
		* [x] 🛫 2026-09-04 ⏳ 2026-09-04 📅 2026-09-04 如果实在验证不了，请向upstream咨询其使用的benchmark ✅ 2026-09-14
			*  验证了一部分： PVM在面临小页申请，且频繁unmap的场景，性能非常差。首先小页申请意味着其不能使用pre-fault，频繁unmap意味着其需要经常释放影子页表。
		* [ ] 接下来需要验证:
			* [ ] 🛫 2026-09-14 📅 2026-09-14 ⏳ 2026-09-16 嵌套虚拟化释放影子页表，或者`drop_spte()`的时机有哪些
			* [x] 🛫 2026-09-14 📅 2026-09-16 ⏳ 2026-09-17 了解PVM针对影子页表的细粒度锁优化 ✅ 2026-09-15
				* 目前发现仅有一个 pv mmu, 但是无论是腾讯内核还是pv default 分支，都未使用该补丁
				* [ ]  需要向社区询问
			* [ ] 🛫 2026-09-14  📅 2026-09-18 ⏳ 2026-09-19 测试论文中提到的一些real world test case


# 2026-09-17
* 测试论文中提到的几款real world app，例如kbuild, Blogbench,  `DaCapo h2` java程序的压测。性能对比嵌套虚拟化差距不大
* 走读 `PV MMU` 的代码
* 找上游了解 [PVM upstream issue](https://github.com/virt-pvm/linux/issues/27)
	* 同步PVM 性能差的猜测
	* `PV MMU`, PVM 细粒度锁优化未合入的原因
	* 以及 使用`L0` 半虚拟化优化嵌套内存虚拟化方案 
* 了解 JANUS 原理。