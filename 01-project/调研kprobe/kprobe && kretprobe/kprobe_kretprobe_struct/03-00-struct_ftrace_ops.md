# ftrace_ops



| 成员名                   | 作用                |
| --------------------- | ----------------- |
| func                  | 作为trampoline 的入口， |
| next                  |                   |
| flags                 |                   |
| private               |                   |
| saved_func            |                   |
| CONFIG_DYNAMIC_FTRACE |                   |
| local_hash            |                   |
| func_hash             |                   |
| trampoline            |                   |
| trampoline_size       |                   |
| list                  |                   |
| ops_func              |                   |
| -                     |                   |
| direct_call           |                   |
flags: `FTRACE_OPS_FL_*`:

| 成员                     | 值                                                                                                                                                              |
| ---------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| ENABLED                | 当ftrace_ops被注册/注销的时候设置                                                                                                                                         |
| DYNAMIC                | 在注册ftrace_ops时设置，表示动态分配ftrace_ops                                                                                                                              |
| SAVE_REGS              | ftrace_ops 想要在function 调用时，save regs，并传递到 callback中，注意如果设置了该bit，但是该架构不支持`CONFIG_DYNAMIC_FTRACE_WITH_REGS=n`, 则ftrace_ops注册时会失败, 除非时设置了`SAVE_REGS_IF_SUPPORTED` |
| SAVE_REGS_IF_SUPPORTED | 和`SAVE_REGS`相同，但是如果架构不支持, ftrace_ops不会失败，但是会传递regs = NULL                                                                                                      |
| IPMODIFY               | 该fops会修改IP register。只能在`SAVE_REGS`设置的情况下配置。但是如果带有该flag bit的ops已经被注册该ops注册的任意function，那么该ops 将会fail to register/set_filter_ip                                   |
| ...                    |                                                                                                                                                                |
