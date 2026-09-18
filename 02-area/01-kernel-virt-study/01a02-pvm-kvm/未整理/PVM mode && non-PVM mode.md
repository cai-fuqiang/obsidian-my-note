---
modified: 2026-09-17T18:25:30+08:00
---
Guest 使用PVM 运行时，有两种模式:
* PVM mode
	* 64-bit smod
	* 64-bit umod
	* 32-bit umod
* non-PVM mode
	* 32-bit smod
	* other

两者的区别是
* 在 PVM mode中，system register 的状态是标准的, guest 可以允许直接运行在
硬件上(在 RING 3). 
* non-PVM 常用于 guest 启动 bring up vcpu。当前运行 non-PVM mode的主要方式是通过[[#non-PVM mode software emulate|软件模拟]]

# reset non_pvm_mode
在`pvm_vcpu_reset()`时，会将`non_pvm_mode`初始化为0
```cpp
pvm_vcpu_reset
=> pvm->non_pvm_mode = true
```

# convert between two mode
* non_pvm_mode -> pvm_mode
  调用`try_to_convert_to_pvm_mode()` 转换，发生在
	* 处理non_pvm_mode vm-exit
	* 处理 pvm event
	* emulate set segment
*  pvm_mode->non_pvm_mode
   在 `pvm_set_segment` 中，切换mode 到non-PVM mode时。
# ref
## commit
* #commit-id  commit-id: d6bd4cc0fe0e9d4cc136cfd719da135a97f01ba0
* #commit-subject KVM: x86/PVM: Implement emulation for non-PVM mode
## non-PVM mode software emulate

```cpp
vcpu_enter_guest
=> for (;;) 
   => kvm_x86_call(vcpu_run)()
      => pvm_vcpu_run
         => if (pvm->non_pvm_mode)
            //==(1)==
            => return EXIT_FASTPATH_NONE
=> kvm_x86_call(handle_exit_irqoff)(vcpu);
   => pvm_handle_exit_irqoff
=> kvm_x86_call(handle_exit)(vcpu, exit_fastpath);
   => pvm_handle_exit
      => if (unlikely(pvm->non_pvm_mode))
		 => handle_non_pvm_mode

handle_non_pvm_mode
# 首先 判断是否能转换为 pvm_mode, 如果能转换, 直接转换，并且这个指令
# 就不用模拟了, 因为其大概率可以在 guest pvm mode中直接执行（也就是
# 在hardware上直接执行
=> if (try_to_convert_to_pvm_mode(vcpu))
   => return 1
# 软件模拟该指令
=> ret = kvm_emulate_instruction(vcpu, 0)
```
1.  [[01a00a-kvm_x86_call(vcpu_run)() 返回EXIT_FASTPATH_REENTER_GUEST才被用作fastpath|只有返回 EXIT_FASTPATH_REENTER_GUEST 才会走fastpath]]