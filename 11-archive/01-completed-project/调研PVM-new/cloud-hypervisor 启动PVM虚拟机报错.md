---
share_link: https://share.note.sx/44njt2ex#o6Ht56ZhDurqLo4rEDL0uA
share_updated: 2026-08-04T20:03:21+08:00
---
```
[   62.347486] ------------[ cut here ]------------
[   62.347492] WARNING: CPU: 29 PID: 1366 at arch/x86/kvm/../../../virt/kvm/pfncache.c:298 __kvm_gpc_refresh+0x41c/0x430 [kvm]
[   62.347576] Modules linked in: kvm_pvm overlay kvm irqbypass efi_pstore pstore zlib_deflate crct10dif_pclmul crct10dif_common crc32_pclmul ghash_clmulni_intel aesni_intel crypto_simd cryptd serio_raw efivarfs [last unloaded: kvm_intel]
[   62.347594] CPU: 29 UID: 0 PID: 1366 Comm: vcpu0 Kdump: loaded Not tainted 6.12.33 #1
[   62.347597] Hardware name: QEMU Standard PC (i440FX + PIIX, 1996), BIOS unknown 2/2/2022
[   62.347599] RIP: 0010:__kvm_gpc_refresh+0x41c/0x430 [kvm]
[   62.347647] Code: ff 0f 00 00 49 01 c4 4c 89 63 68 e8 9e 71 ff ff 48 8b 5b 70 e9 9d fe ff ff 48 85 d2 74 13 49 89 50 08 48 89 d7 e9 c6 fc ff ff <0f> 0b e9 39 fe ff ff 31 ff e9 b8 fc ff ff 66 0f 1f 44 00 00 90 90
[   62.347650] RSP: 0000:ffffaa26417ebca8 EFLAGS: 00010246
[   62.347652] RAX: 0000000000001001 RBX: ffffa3978cff16f8 RCX: 0000000000000000
[   62.347654] RDX: ffffa39680000001 RSI: ffffffffffffffff RDI: ffffa3978cff16f8
[   62.347655] RBP: ffffa39680000000 R08: 0000000000000000 R09: 0000000000000000
[   62.347657] R10: 0000000000000000 R11: 0000000000000000 R12: ffffa3978cff1740
[   62.347658] R13: 0000000000000001 R14: ffffa3978cff07a8 R15: ffffa3978cff0038
[   62.347660] FS:  0000000000000000(0000) GS:ffffa39af45fe000(0000) knlGS:0000000000000000
[   62.347662] CS:  0010 DS: 0000 ES: 0000 CR0: 0000000080050033
[   62.347663] CR2: ffffffff82751690 CR3: 000000010eaae004 CR4: 0000000000170ef0
[   62.347667] Call Trace:
[   62.347671]  <TASK>
[   62.347673]  kvm_gpc_refresh+0x4a/0x80 [kvm]
[   62.347727]  pvm_get_vcpu_struct+0x34/0x70 [kvm_pvm]
[   62.347733]  __do_pvm_event+0x22/0x310 [kvm_pvm]
[   62.347737]  pvm_inject_exception+0x42/0x70 [kvm_pvm]
[   62.347740]  kvm_check_and_inject_events+0x241/0x4a0 [kvm]
[   62.347802]  kvm_arch_vcpu_ioctl_run+0xbdf/0x1720 [kvm]
[   62.347865]  kvm_vcpu_ioctl+0x2ed/0x810 [kvm]
[   62.347914]  ? __seccomp_filter+0xd4/0x4e0
[   62.347921]  __x64_sys_ioctl+0x8f/0xc0
[   62.347927]  do_syscall_64+0x4f/0x120
[   62.347934]  entry_SYSCALL_64_after_hwframe+0x76/0x7e
[   62.347939] RIP: 0033:0x7f4e5bef198e
[   62.347942] Code: 63 f6 48 8d 44 24 60 48 89 54 24 30 48 89 44 24 10 48 8d 44 24 20 48 89 44 24 18 b8 10 00 00 00 c7 44 24 08 10 00 00 00 0f 05 <48> 63 f8 e8 0a e7 ff ff 48 83 c4 58 c3 41 57 41 56 41 55 41 54 49
[   62.347944] RSP: 002b:00007f4ddb3f62f0 EFLAGS: 00000206 ORIG_RAX: 0000000000000010
[   62.347946] RAX: ffffffffffffffda RBX: 00007f4ddb3f6548 RCX: 00007f4e5bef198e
[   62.347951] RDX: 0000000000000000 RSI: 000000000000ae80 RDI: 0000000000000024
[   62.347953] RBP: 0000000000000500 R08: 00007f4e5c0adab0 R09: 0000000000000000
[   62.347954] R10: 00007f4ddb3f63a8 R11: 0000000000000206 R12: 00007f4ddb3f6470
[   62.347956] R13: 00007f4e5bf10b84 R14: 00007f4e5c203720 R15: 00007f4e5c1e0000
[   62.347959]  </TASK>
[   62.347960] ---[ end trace 0000000000000000 ]---
```