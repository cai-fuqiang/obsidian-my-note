---
created: 2026-09-14T17:52:41+08:00
modified: 2026-09-18T19:44:49+08:00
---
# Question 

some questions about PVM PF performance
# text

In Section 4.1 Micro-benchmarks of the PVM paper, the paragraph on **Page faults** mentions the testing methodology of the micro-benchmarks:

> We used a micro-benchmark to repeatedly allocate and release 1MB of memory in a guest’s virtual address space and access the allocated data at page granularity. This process continued until the accessed data reached 4GB.

If I understand correctly, the test scenario should be as follows: 
1. A single container with multiple vCPUs. 
2. Each time, 1 MB of memory is dynamically allocated, accessed at a 4 KB granularity, and then released after the access is complete. 
3. This cycle repeats until the total amount of memory accessed reaches 4 GB.

So, following the logic above, I wrote this benchmark at this [link](https://github.com/cai-fuqiang/kernel_test/blob/master/pf_trigger/pf_trigger.c).

However, when I run the test, I found that it did not meet the expectations performance in the paper.

First, frequently allocating and freeing 1 MB of memory may cause the allocated memory to be confined to a very small range of physical memory addresses. This causes the following: when a nested VM executes this program, **almost `#PF` are handled within the L2 kernel**. In the PVM scenario, every unmap of the L2 guest flushes the TLB, which in turn forces L1 to **sync the SPTEs**. As a result, all virtual addresses accessed by the L2 user **in the next round must trigger page faults**. Even worse, when a `#PF` is triggered on a virtual memory region allocated by `mmap()`, only a single gpte is filled in, which prevents the shadow page table pre-fault mechanism from taking effect. In other words, **every address access triggers two `#PF`**. As a result, the performance is far lower than that of a nested VM.

> [!note] Even when `mmap()` is made to use the `MAP_POPULATE` flag (which triggers the shadow page table pre-fault mechanism), PVM's performance in this scenario is still far lower than that of KVM-nested.

| test-case                          | cost/s                                         |
| ---------------------------------- | ---------------------------------------------- |
| bare-1                             | 1.14                                           |
| kvm_ept-1                          | 1.37                                           |
| kvm_nst-1                          | <mark style="background:#affad1">1.2</mark>    |
| kvm_pvm-1                          | <mark style="background:#ff4d4f">6.4</mark>    |
| kvm_pvm-1(mmap with MAP_POPULATE)  | <mark style="background:#fdbfff">1.995 </mark> |
| bare-16                            | 1.356                                          |
| kvm_ept-16                         | 3.861                                          |
| kvm_nst-16                         | <mark style="background:#affad1">3.274</mark>  |
| kvm_pvm-16                         | <mark style="background:#ff4d4f">25.443</mark> |
| kvm_pvm-16(mmap with MAP_POPULATE) | <mark style="background:#fdbfff">9.827 </mark> |
In addition, I noticed that when testing with multiple threads (16 threads), PVM frequently contends for `mmu_lock`.

***

Therefore, I have some questions I would like to ask you:
1. Would mind sharing your page fault micro-benchmark program?
2. The fine-grained lock optimization mentioned in the paper — has it not been merged into any branch of this project?
3. I tried a different way of testing page faults: mmap 1 GB of memory and access it page by page. In this scenario, PVM achieved good performance. Can I understand it as follows: are the main advantageous scenarios for PVM:
	1. The L2 VM is not fully warmed up.
	2. L2 apps do not frequently allocate and free memory dynamically.
	3. It is best if the page tables can be prepared before the PF is triggered, similar to guest kernel boot...(can use prefault to reduce `#PF`)
4. I noticed the `pv_mmu` feature in the `pv_mmu_draft` branch.  However, I noticed that it has not been merged into the default branch, and it has not been merged into [Tencent Cloud’s kernel PVM branch](https://gitee.com/OpenCloudOS/OpenCloudOS-Kernel/tree/linux-6.6%2Freleased%2Fcube-pvm/) either. May I ask why this feature was dropped? (With my limited understanding, I see one risk: once `sp->unsync_children` is no longer tracked, unsync SPs can no longer be zapped via `kvm_mmu_free_roots`. Although `KVM_HC_PV_MMU_RELEASE_PT` can mitigate this problem, when there are many sleeping tasks in the system, intuitively it would still greatly increase the probability of the `kvm->arch.active_mmu_pages` list be full...)
5. In this [link](https://lore.kernel.org/all/CAJhGHyChprt9LvLXXDeu1KwS4_V5mqhUTwJyDvqca-S_PSy6zg@mail.gmail.com/#t) ，I noticed that Jiangshan mentioned:

   > The reason we are experimenting with modifications to L0 is because we have many physical machines. Developing this technology getting help from L0 for L2 paging could provide us and others who have their own physical machines with an additional option.
   
   It seems that this is handled by passing the L2 hypercall directly through to L0. I’m very interested in this. Would it be convenient to share that part of the patch, or briefly explain how it works?



# reply2

hi， Thank you so much for your detailed reply.

I spent some time reading through the JANUS paper (some sections also answered some of my initial questions, such as the performance differences between PVM and nested KVM on inactive physical memory and active physical memory). It seems that JANUS has effectively improved PVM memory virtualization performance **across various types of memory workloads**—It combines the advantages of PVM's cheaper world switch while avoiding the drawbacks of PVM's shadow page table. it looks like a really great solution!!!

**So, if I may ask, is there any intention to ==open-source this solution==? If so, could you share the expected open-source ==date==?**

***
PS: I have a technical detail I’d like to ask you about.

In the current PVM implementation, `host_mmu_root_pgd` copies the L1 kernel  PGD entries, so that **L2 can get the ==same VA-to-PA mapping== for the switcher as L1.**

Later, during the establishment of the shadow page table, this PGD page is copied into the shadow PGD used for L2. Although at this point the PGD loaded by L2’s CR3 contains the L1 kernel memory mappings, since **L2 runs in RING3**, it does not **have permission to access L1 kernel memory** (including the switcher; it can jump to the switcher via event/syscall, but this is a safe path).

In JANUS, however, the design still follows PVM: it maps the switcher virtual address spaces of GVA<sub>L1</sub> and GVA<sub>L2</sub> to the same GPA<sub>switcher_L1</sub> physical address  and in EPT<sub>02</sub> it must likewise ensure that the mapping of {GPA<sub>switcher_L1</sub>, HPA<sub>switcher</sub>} is the same as in EPT<sub>01</sub>, so that GVA<sub>L1</sub> and GVA<sub>L2</sub> of switcher code map to the same HPA. **But JANUS does not track GPT<sub>L2</sub>, which means ==L2 can map a GVA to SWITCHER GPA ==**. And more seriously, EPT itself NOT carries U/S attributes, which means the **switcher code is ==visible to L2==**.

The paper mentions that L2 and L1 have different physical address spaces. Simply put, GPA<sub>L2</sub> must have the V bit (bit 44) to located in a higher space, while GPA<sub>L1</sub> is located in a lower space. I personally think the significance of this is more about specifying that GPA<sub>L2</sub> should not fall into GPA<sub>L1</sub>, but it still cannot prevent access it. In addition, when L0 constructs the EPT<sub>02</sub> root page, it sets the `suppress #VE` bit to prevent the switcher code from running when EPT02 is loaded, which would trigger a triple fault. Therefore, access to the switcher cannot be directly handed over to L1 to determine whether the access is legitimate. **So, I personally think the current scheme can only set the mapping of the switcher portion in EPT02 to RO, thereby preventing L2 from writing to the switcher, but ==it cannot prevent L2 from accessing it==**.

May I ask whether my understanding here is correct?



# reply 3

Oh... I think I may have gotten one point wrong: 
I originally thought that the _`ept violation` caused by L2 accessing the **switcher** is handled **directly by L0**_, because I noticed it in the paper :

> _Note that, in our design, the **Suppress `#VE` bit (bit 63) is set** for switcher EPT entries to force a normal EPT violation VM exit for **on-demand switcher** construction, while it remains cleared for regular L2 EPT entries to enable in-guest `#VE` handling._

This isn't hard to understand. If the EPT violation caused by the switcher were handled directly by L1, then when the `#VE` is triggered, L1 would still load EPT<sub>02</sub>. The switcher in EPT<sub>02</sub> is mapped on demand, so it would result in a triple fault.

***

However, JANUS’s design principles require that:

> _**all L2 visible events, such as page faults**, system calls, and interrupts, are either handled natively by L2 or efficiently processed within L1, and_

This seems to indicate that all EPT<sub>02</sub> page-table setup—including the shadow root page and the switcher—is performed by L0 upon notification from L1 via `JANUS_MAP`.


I’d like to ask: under this restriction, in the solution to this problem, is it the case that _when L0 receives an EPT violation from L1, it will **switch from EPT02 to EPT01 in L0**_?