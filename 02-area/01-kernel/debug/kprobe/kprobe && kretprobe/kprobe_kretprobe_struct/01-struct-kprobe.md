# kprobe

作用: kprobe API的 参数, 用作用户自定义kprobe point相关信息, 同时也是一个runtime struct

| 成员名          | 成员类型 | 作用                                                                                         |
| ------------ | ---- | ------------------------------------------------------------------------------------------ |
| addr         | in   | probe point 地址                                                                             |
| symbol_name  | in   | 通过symbol 字符串来指示要probe 的符号                                                                  |
| offset       | in   | probe是==一个点==(或者说一条指令位置)，其允许在 symbol中指定 一个offset (probe_point_addr = symbol_addr + offset) |
| pre_handler  | in   | 用来指定在该probe point执行之前执行的函数                                                                 |
| host_handler | in   | 用来指定在probe point 执行之后执行的函数                                                                 |
| list         | rt   | 这个是否表示在一个kprobe point上添加多个函数?                                                              |
| opcode       | rt   | 保存原始操作码                                                                                    |
| ainsn        |      | #TODO                                                                                      |
