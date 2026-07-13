作用: 和[[01-struct-kprobe|kprobe]]相同

| 成员名            | 成员类型 | 作用                                                                                        |
| -------------- | ---- | ----------------------------------------------------------------------------------------- |
| **kprobe**     | rt   | 在实现过程中，kretprobe最终转换为kprobe，执行后面的流程，==方便函数参数定义==                                          |
| entry_handler  | in   | 函数执行开始的执行的函数                                                                              |
| handler        | in   | 函数返回时执行的函数                                                                                |
| data_size      | in   | kretprobe允许使用一个数据结构，来让entry_handler 和 handler 交流, 类似于两者之间的全局变量                            |
| maxactive      | in   | 最大并发活动实例数，==因为kretprobe 的资源在 `function_entry-> function_ret` 期间一直占用, 所以为了让资源更可控需要给一个最大值== |
| nmissed        | rt   | 因`maxactive` 跳过的次数                                                                        |
| free_instances | rt   | 按照`maxactive`分配的 实例，都会挂到 free_instances上                                                  |
| rh(rethook)    | rt   |                                                                                           |
## kretprobe_instance

每个活动实例的 数据结构.

| 成员名                | 成员类型 | 作用  |
| ------------------ | ---- | --- |
| node(rethook_node) |      |     |
| rph                |      |     |
| ret_addr           |      |     |
| fp                 |      |     |
| data               |      |     |
## rethook

| 成员名     | 成员类型 | 作用                          |
| ------- | ---- | --------------------------- |
| data    | in   | 在retprobe中指向 kretprobe      |
| handler |      | kretprobe_rethook_handler() |
| pool    |      |                             |
| rcu     |      |                             |
