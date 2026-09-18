---
type: literature
status: processed
category: pvm_syscall
summary: Guest 调用syscall 首先要, guest 调用syscall时，首先要进入 switcher 入口，switcher 在将代码跳转回guest，而`entry_SYSCALL_64_pvm` 就是Guest 内核侧处理syscall 的入口函数。
created: 2026-09-04T13:44:30+08:00
modified: 2026-09-17T18:24:56+08:00
QA:
  - Guest 调用syscall会经过哪些流程
  - entry_SYSCALL_64_pvm && entry_SYSCALL_64_switcher怎么配合
share_link: https://share.note.sx/ch5a1t25#YbGbPJDzDHBYHsiEESbKSQ
share_updated: 2026-09-10T15:08:42+08:00
---
# summary

> [!summary]
> `= this.summary`

# 引用

## 涉及函数
 
| 函数名                                  | 调用方       | 作用                                                  |
| ------------------------------------ | --------- | --------------------------------------------------- |
| entry_SYSCALL_64_pvm                 | PVM guest | -                                                   |
| idt_syscall_init                     | PVM guest | 将该入口(`entry_SYSCALL_64_pvm`) 写入 `MSR_LSTAR`         |
| pvm_set_msr                          | PVM hyper | 处理`MSR_LSTAR`将寄存器值记录至`pvm->msr_lstar`               |
| pvm_vcpu_run_noinstr                 | PVM hyper | 将`pvm->msr_lstar` 赋值到`tss_ex->smod_entry`           |
| entry_SYSCALL_64_switcher_safe_stack | PVM hyper | syscall switcher入口代码，负责最终将代码跳转到`tss_ex->smod_entry` |
# details

整体流程:
```
PVM Guest user           switcher                PVM Guest kernel
syscall
                    entry_SYSCALL_64_switcher
                    =>  movq TSS_extra(smod_entry), %rcx
                    => sysretq
                                                 entry_SYSCALL_64_pvm

```

## 适用边界

* `entry_SYSCALL_64_pvm`是guest syscall入口，中断和异常入口有其他符号承担。

# related

## 可提炼的永久笔记
- [ ]

## 其他引用笔记

# TODO
- [ ] `entry_SYSCALL_64_switcher` 作用