---
share_link: https://share.note.sx/qos4s091#L8qu6r2wIlv8ElDL3tzCow
share_updated: 2026-08-25T09:29:56+08:00
modified: 2026-09-08T18:37:06+08:00
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
		* [ ] 🛫 2026-09-04 ⏳ 2026-09-04 📅 2026-09-05 重新编写Page Fault microbench来验证PVM的优势
		* [ ] 🛫 2026-09-04 ⏳ 2026-09-04 📅 2026-09-04 如果实在验证不了，请向upstream咨询其使用的benchmark