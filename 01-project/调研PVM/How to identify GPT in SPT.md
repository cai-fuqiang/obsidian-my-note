假设某个虚拟机的某个进程的地址空间是全新的，在GPT 中没有映射，当然在hypervisor 中都没有SPT映射。此时访问一个virt addr 会产生PF，该PF最终会通过Hypervisor "原样" 注入到VM。

当Guest 收到 `#PF`后，进入 PAGE FAULT HANDLER 处理缺页异常，其会建立一个页表链，并在每个页表中，填写部分Entry，此时在hypervisor 看来，Guest访问的这些页表和其他页表没什么两样。填写完最后一级 的 page table entry (映射到page frame 的 GPA)，Guest kernel 返回guest userspace ，guest userspace再次访问该 virt address, 此时由于Hypervisor并没有创建SPT, 再次出发PF。

Hypervisor 收到PF后，开始创建 SPT, 其会根据 **Guest CR3**, 做Guest Page Table Walk(也就是遍历刚刚的Guest 新创建的页表链)。**在这个过程中就可以发现哪些Page 是 GPT了，此时遍历之前建立好的所有的SPT，==如果有SPT映射到该GPT physical address，标记为 WP==**

但是，这个流程仅仅是未做任何高级优化的流程。