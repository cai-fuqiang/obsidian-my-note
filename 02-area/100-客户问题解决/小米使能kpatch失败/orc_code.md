
# orc_find
```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/runninglinuxkernel_5.0/rlk_5.0/arch/x86/kernel/unwind_orc.c"
LINES: "116-160"
TITLE: "orc_find"
FONT_SIZE: 12
COMMENTS:
  134: |-
    因为IP是稀疏的，需要一个稀疏的映射表，让实际存在的ip和具体的orc 
    entry / ip table映射起来,
```

# __orc_find

```embed-cpp
PATH: "https://raw.githubusercontent.com/cai-fuqiang/runninglinuxkernel_5.0/rlk_5.0/arch/x86/kernel/unwind_orc.c"
LINES: "29-56"
TITLE: "__orc_find"
FONT_SIZE: 12
COMMENTS:
  45: 使用二分法查找
  48: |-
    而 `ip_table` 里面存放的，是==当前地址和其所作用的IP 的偏移==
    ```embed-cpp
    PATH: "https://raw.githubusercontent.com/cai-fuqiang/runninglinuxkernel_5.0/rlk_5.0/arch/x86/kernel/unwind_orc.c"
    LINES: "24-27"
    TITLE: "orc_ip"
    ```
  55: |- 
    一个ip对应`ip_table` entry 以及一个 `orc_entry`, 所以其两者针对于table 首地址的偏移相同
```

