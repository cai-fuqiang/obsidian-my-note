
> [!PDF|yellow] [[sosp2023-pvm-paper.pdf#page=7&selection=91,25,97,1&color=yellow|📖 PVM 涉及的两个Hypervisor 内核模块]]
> 
> * kvm.ko: [[sosp2023-pvm-paper.pdf#page=7&selection=98,0,101,52 |📖 提供传统KVM的功能，确保于软件兼容性]]
> * kvm-pvm.ko: [[sosp2023-pvm-paper.pdf#page=7&selection=102,0,111,25| 📖  提供基本的PVM 功能]]
> ```ad-tip
> **我个人理解 kvm-pvm.ko和kvm-intel.ko功能类似，都是提供==底层硬件加速功能==**, 只不过前者是半虚拟化加速，后者是VMX feature 硬件加速
> ```
