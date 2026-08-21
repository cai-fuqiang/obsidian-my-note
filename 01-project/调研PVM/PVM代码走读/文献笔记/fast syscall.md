# fast syscall引入背景

> [!attention] 奔腾4在syscall测试中，比奔腾三相比出现了严重的性能下降。
> 参考 [Intel P6 vs P7 system call performance](https://lore.kernel.org/all/200212090830.gB98USW05593@flux.loup.net/), 这直接加速了的引入[fast syscall](https://lwn.net/Articles/18411/)

# why syscall fast

> [!question] 为什么syscall 非常快
> 原因是 `syscall`机制是专门针对于系统调用这个特殊的场景做的定制设计。该指令执行时，几乎不会涉及内存访问! 

# 参考链接
1. [Syscall and Sysret](https://cyp.sh/blog/syscallsysret)
2. [How to speed up system calls](https://lwn.net/Articles/18411/)
3. [P4由于超长流水线，在模式切换时延迟较高](https://lkml.iu.edu/hypermail/linux/kernel/0212.1/0201.html)
4. [Why are "new" syscall faster than "interupt" syscalls?](https://unix.stackexchange.com/questions/584197/why-are-new-syscall-faster-than-interupt-syscalls)
