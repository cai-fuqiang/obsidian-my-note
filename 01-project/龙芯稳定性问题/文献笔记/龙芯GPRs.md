LoongArch has 32 GPRs ( `$r0` ~ `$r31` ); each one is 32-bit wide in LA32 and 64-bit wide in LA64. `$r0` is hard-wired to zero, and the other registers are not architecturally special. (Except `$r1`, which is hard-wired as the link register of the BL instruction.)

The kernel uses a variant of the LoongArch register convention, as described in the LoongArch ELF psABI spec, in [References](https://docs.kernel.org/arch/loongarch/introduction.html#loongarch-references):

| Name          | Alias       | Usage               | Preserved across calls |
| ------------- | ----------- | ------------------- | ---------------------- |
| `$r0`         | `$zero`     | Constant zero       | Unused                 |
| `$r1`         | `$ra`       | Return address      | No                     |
| `$r2`         | `$tp`       | TLS/Thread pointer  | Unused                 |
| `$r3`         | `$sp`       | Stack pointer       | Yes                    |
| `$r4`-`$r11`  | `$a0`-`$a7` | Argument registers  | No                     |
| `$r4`-`$r5`   | `$v0`-`$v1` | Return value        | No                     |
| `$r12`-`$r20` | `$t0`-`$t8` | Temp registers      | No                     |
| `$r21`        | `$u0`       | Percpu base address | Unused                 |
| `$r22`        | `$fp`       | Frame pointer       | Yes                    |
| `$r23`-`$r31` | `$s0`-`$s8` | Static registers    | Yes                    |

参考:

https://docs.kernel.org/arch/loongarch/introduction.html#gprs