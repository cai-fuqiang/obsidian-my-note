---
modified: 2026-09-10T17:36:21+08:00
share_link: https://share.note.sx/hdzozw00#NiupvMnXetvuo5W6VvpWnw
share_updated: 2026-09-10T15:08:37+08:00
---
参考代码:
```cpp
vmx_exec_control
=> 	if (enable_ept)
		exec_control &= ~(CPU_BASED_CR3_LOAD_EXITING |
				  CPU_BASED_CR3_STORE_EXITING |
				  CPU_BASED_INVLPG_EXITING);

```