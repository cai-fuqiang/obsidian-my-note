```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/linux/v7.1-rc3/arch/x86/kernel/ftrace_64.S"
LINES: "155-198"
TITLE: "ftrace_caller"
FONT_SIZE: 12
COMMENTS:
  156: 告诉编译器不要在这里加入ENDBR64 指令
  158: 构造frame pointer 栈桢，并保存 mcount_regs(大小为FRAME_SIZE)
  164: 重新赋值了下 SP
       ```ad-todo
       还是得看下这个SP在什么地方起作用
       ```
  166: 为ftrace_stub调用准备参数
  169: 第三个参数为 当前的ftrace_ops(ftrace_caller_op_ptr待展开)
  171: 第四个参数为 regs
  180: ftrace_stub在enable时，最终会被替换为既定的function
```

# save_mcount_regs
```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/linux/v7.1-rc3/arch/x86/kernel/ftrace_64.S"
LINES: "55-115"
TITLE: "save_mcount_regs"
FONT_SIZE: 12
COMMENTS:
  57: 使用FTRACE_POINTER，需要在堆栈中，将SP保存
  61: |-
    有两种机制:
    * mcount: 在函数建立栈桢之后被调用
    * fentry: 在函数执行第一条指令之前调用
  70: |-
    如果A() call B(), 而我们trace A()，则需要在 A()函数的第一条指令
    (fentry)处，插入call ftrace_caller.
    那么此时堆栈
    ```
    Parent RIP # A()的返回地址，即B()调用A()的下一条指令。
    RIP        # ftrace_caller的返回地址，即 A() 的第二条指令
    rbp        # 59行压入的, 也是当前SP的地址
    ```
    现在的问题在于, B()->A()后，理论上应该由A()来保存parent SP, 但是现在由于A()第一行指令就进入了
    `trampoline()`, 那么那么就需要trampoline完成A()的栈桢的构建。
  103: get parent RIP
  106: |-
    get RIP, 注意103,106 行都不是指向的为frame pointer伪造的堆栈，而是通过call调用自动压入的ip位置
    但是需要注意的是RIP指向的是调用call的下一条地址，对于`A()->trampoline`, RIP = A() + sizeof(call)
    但是这符合pt_regs->ip的定义。
    而RDI, 应该指向的是probe point, 也就是A()， 所以在114行应该减去 mcount 指令的长度。
```

# restore_mcount_regs

```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/linux/v7.1-rc3/arch/x86/kernel/ftrace_64.S"
LINES: "117-132"
TITLE: "restore_mcount_regs"
FONT_SIZE: 12
COMMENTS:
  120: restore ftrace pointer 中保存的寄存器
  130: 直接将所有的栈退回，这是rsp为`return function ip`，接下来可以直接调用ret返回
```

# MCOUNT_REG_SIZE

```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/linux/v7.1-rc3/arch/x86/kernel/ftrace_64.S"
LINES: "19-28"
TITLE: "MCOUNT_REG_SIZE"
FONT_SIZE: 12
COMMENTS:
  20: 如果配置了 FRAME POINTER, 则该frame size需要加三个rbp和两个ip, 见save_mcount_regs
      为frame pointer额外做的堆栈准备
  24: 如果不使用FRAME POINTER，则不需要额外准备任何堆栈内容
```

# ftrace_regs_caller

和`ftrace`不一样的是构造出完整的`pt_regs`

```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/linux/v7.1-rc3/arch/x86/kernel/ftrace_64.S"
LINES: "201-329"
TITLE: "ftrace_regs_caller"
FONT_SIZE: 12
COMMENTS:
  207: |-
    8表示pushfp占用堆栈的大小
```
