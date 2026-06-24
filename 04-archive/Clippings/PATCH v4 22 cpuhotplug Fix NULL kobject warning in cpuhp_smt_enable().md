---
title: "[PATCH v4 2/2] cpu/hotplug: Fix NULL kobject warning in cpuhp_smt_enable()"
source: "https://lore.kernel.org/lkml/20260610075202.3597031-3-ruanjinjie@huawei.com/"
author:
published:
created: 2026-06-15
description:
tags:
  - "clippings"
---
```
From: Jinjie Ruan <ruanjinjie@huawei.com>
To: <catalin.marinas@arm.com>, <will@kernel.org>, <corbet@lwn.net>,
    <skhan@linuxfoundation.org>, <punit.agrawal@oss.qualcomm.com>,
    <ruanjinjie@huawei.com>, <mrigendra.chaubey@gmail.com>,
    <suzuki.poulose@arm.com>, <chenl311@chinatelecom.cn>,
    <fengchengwen@huawei.com>, <maz@kernel.org>,
    <timothy.hayes@arm.com>, <lpieralisi@kernel.org>, <arnd@arndb.de>,
    <gshan@redhat.com>, <jic23@kernel.org>,
    <dietmar.eggemann@arm.com>, <sudeep.holla@kernel.org>,
    <pierre.gondois@arm.com>, <linux-arm-kernel@lists.infradead.org>,
    <linux-doc@vger.kernel.org>, <linux-kernel@vger.kernel.org>
Subject: [PATCH v4 2/2] cpu/hotplug: Fix NULL kobject warning in cpuhp_smt_enable()
Date: Wed, 10 Jun 2026 15:52:02 +0800    [thread overview]
Message-ID: <20260610075202.3597031-3-ruanjinjie@huawei.com> (raw)
In-Reply-To: <20260610075202.3597031-1-ruanjinjie@huawei.com>

On arm64, when booting with \`maxcpus\` greater than the number of present
CPUs (e.g., QEMU -smp cpus=4,maxcpus=8), some CPUs are marked as 'present'
but have not yet been registered via register_cpu(). Consequently,
the per-cpu device objects for these CPUs are not yet initialized.

In cpuhp_smt_enable(), the code iterates over all present CPUs. Calling
_cpu_up() for these unregistered CPUs eventually leads to
sysfs_create_group() being called with a NULL kobject (or a kobject
without a directory), triggering the following warning in
fs/sysfs/group.c:

    if (WARN_ON(!kobj || (!update && !kobj->sd)))
        return -EINVAL;

When booting with ACPI, arm64 smp_prepare_cpus() currently sets all
enumerated CPUs as "present" regardless of their status in the MADT. This
causes issues with SMT hotplug control. For instance, with QEMU's
"-smp 4,maxcpus=8" configuration, the MADT GICC entries are populated as
follows:

1. The first four CPUs: \`Enabled\` set but \`Online Capable\` not set.

2. The remaining four CPUs: \`Online Capable\` set but \`Enabled\` not set
   to support potential hot-plugging.

Fix this by:

1. When booting with ACPI, checking the ACPI_MADT_ENABLED flag in the GICC
   entry before calling set_cpu_present() during SMP initialization.

2. Properly managing the present mask in acpi_map_cpu() and
   acpi_unmap_cpu() to support actual CPU hotplug events, This aligns with
   other architectures like x86 and LoongArch.

3. Update the arm64 CPU hotplug documentation to no longer state that all
   online-capable vCPUs are marked as present by the kernel at boot time.

This ensures that only physically available or explicitly enabled CPUs
are in the present mask, keeping the SMT control logic consistent with
the actual hardware state.

How to reproduce:

    1. echo off > /sys/devices/system/cpu/smt/control
        psci: CPU1 killed (polled 0 ms)
        psci: CPU3 killed (polled 0 ms)

    2. echo 2 > /sys/devices/system/cpu/smt/control

    Detected PIPT I-cache on CPU1
    GICv3: CPU1: found redistributor 1 region 0:0x00000000080c0000
    CPU1: Booted secondary processor 0x0000000001 [0x410fd082]
    Detected PIPT I-cache on CPU3
    GICv3: CPU3: found redistributor 3 region 0:0x0000000008100000
    CPU3: Booted secondary processor 0x0000000003 [0x410fd082]
    ------------[ cut here ]------------
    WARNING: fs/sysfs/group.c:137 at internal_create_group+0x41c/0x4bc, CPU#2: sh/181
    Modules linked in:
    CPU: 2 UID: 0 PID: 181 Comm: sh Not tainted 7.0.0-rc1-00010-g8d13386c7624 #142 PREEMPT
    Hardware name: QEMU KVM Virtual Machine, BIOS 0.0.0 02/06/2015
    pstate: 20000005 (nzCv daif -PAN -UAO -TCO -DIT -SSBS BTYPE=--)
    pc : internal_create_group+0x41c/0x4bc
    lr : sysfs_create_group+0x18/0x24
    sp : ffff80008078ba40
    x29: ffff80008078ba40 x28: ffff296c980ad000 x27: ffff00007fb94128
    x26: 0000000000000054 x25: ffffd693e845f3f0 x24: 0000000000000001
    x23: 0000000000000001 x22: 0000000000000004 x21: 0000000000000000
    x20: ffffd693e845fc10 x19: 0000000000000004 x18: 00000000ffffffff
    x17: 0000000000000000 x16: 0000000000000000 x15: 0000000000000000
    x14: 0000000000000358 x13: 0000000000000007 x12: 0000000000000350
    x11: 0000000000000008 x10: 0000000000000407 x9 : 0000000000000400
    x8 : ffff00007fbf3b60 x7 : 0000000000000000 x6 : ffffd693e845f3f0
    x5 : ffff00007fb94128 x4 : 0000000000000000 x3 : ffff000000f4eac0
    x2 : ffffd693e7095a08 x1 : 0000000000000000 x0 : 0000000000000000
    Call trace:
     internal_create_group+0x41c/0x4bc (P)
     sysfs_create_group+0x18/0x24
     topology_add_dev+0x1c/0x28
     cpuhp_invoke_callback+0x104/0x20c
     __cpuhp_invoke_callback_range+0x94/0x11c
     _cpu_up+0x200/0x37c
     cpuhp_smt_enable+0xbc/0x114
     control_store+0xe8/0x1d4
     dev_attr_store+0x18/0x2c
     sysfs_kf_write+0x7c/0x94
     kernfs_fop_write_iter+0x128/0x1b8
     vfs_write+0x2b0/0x354
     ksys_write+0x68/0xfc
     __arm64_sys_write+0x1c/0x28
     invoke_syscall+0x48/0x10c
     el0_svc_common.constprop.0+0x40/0xe8
     do_el0_svc+0x20/0x2c
     el0_svc+0x34/0x124
     el0t_64_sync_handler+0xa0/0xe4
     el0t_64_sync+0x198/0x19c
    ---[ end trace 0000000000000000 ]---

Cc: Catalin Marinas <catalin.marinas@arm.com>
Cc: Jonathan Cameron <jic23@kernel.org>
Cc: James Morse <james.morse@arm.com>
Cc: Yicong Yang <yangyicong@hisilicon.com>
Cc: stable@vger.kernel.org
Link: https://uefi.org/specs/ACPI/6.5/05_ACPI_Software_Programming_Model.html#gic-cpu-interface-gicc-structure
Fixes: eed4583bcf9a6 ("arm64: Kconfig: Enable HOTPLUG_SMT")
Reviewed-by: Catalin Marinas <catalin.marinas@arm.com>
Suggested-by: Catalin Marinas <catalin.marinas@arm.com>
Signed-off-by: Jinjie Ruan <ruanjinjie@huawei.com>
---
v4:
- Udpate the arm64 cpu-hotplug documentation to make it more clear.
v3:
- Update the arm64 cpu-hotplug documentation as Catalin suggested.
- Update the commit message.
v2:
- Update the fix way.
---
 Documentation/arch/arm64/cpu-hotplug.rst | 28 ++++++++++++++----------
 arch/arm64/kernel/acpi.c                 |  2 ++
 arch/arm64/kernel/smp.c                  | 12 +++++++++-
 3 files changed, 29 insertions(+), 13 deletions(-)

diff --git a/Documentation/arch/arm64/cpu-hotplug.rst b/Documentation/arch/arm64/cpu-hotplug.rst
index 8fb438bf7781..7c3379b704aa 100644
--- a/Documentation/arch/arm64/cpu-hotplug.rst
+++ b/Documentation/arch/arm64/cpu-hotplug.rst
@@ -47,11 +47,12 @@ ever have can be described at boot. There are no power-domain considerations
 as such devices are emulated.
 
 CPU Hotplug on virtual systems is supported. It is distinct from physical
-CPU Hotplug as all resources are described as \`\`present\`\`, but CPUs may be
-marked as disabled by firmware. Only the CPU's online/offline behaviour is
-influenced by firmware. An example is where a virtual machine boots with a
-single CPU, and additional CPUs are added once a cloud orchestrator deploys
-the workload.
+CPU Hotplug as all vCPU resources are statically described in the firmware
+configuration tables (e.g. MADT), meaning their maximum possible count is
+known at boot. However, vCPUs that are not enabled at boot are not marked
+as \`\`present\`\` by the kernel until they are hotplugged. An example is where
+a virtual machine boots with a single CPU, and additional CPUs are added
+once a cloud orchestrator deploys the workload.
 
 For a virtual machine, the VMM (e.g. Qemu) plays the part of firmware.
 
@@ -60,16 +61,19 @@ brought online. Firmware can enforce its policy via PSCI's return codes. e.g.
 \`\`DENIED\`\`.
 
 The ACPI tables must describe all the resources of the virtual machine. CPUs
-that firmware wishes to disable either from boot (or later) should not be
-\`\`enabled\`\` in the MADT GICC structures, but should have the \`\`online capable\`\`
-bit set, to indicate they can be enabled later. The boot CPU must be marked as
-\`\`enabled\`\`.  The 'always on' GICR structure must be used to describe the
-redistributors.
+that are hot-pluggable must have the \`\`online capable\`\` bit set and the
+\`\`enabled\`\` bit cleared in the MADT GICC structures to indicate they can be
+enabled later. The boot CPU must be marked as \`\`enabled\`\` with its
+\`\`online capable\`\` bit cleared. The 'always on' GICR structure must be used
+to describe the redistributors.
 
 CPUs described as \`\`online capable\`\` but not \`\`enabled\`\` can be set to enabled
 by the DSDT's Processor object's _STA method. On virtual systems the _STA method
-must always report the CPU as \`\`present\`\`. Changes to the firmware policy can
-be notified to the OS via device-check or eject-request.
+must always set the \`\`ACPI_STA_DEVICE_PRESENT\`\` bit, while toggling the
+\`\`ACPI_STA_DEVICE_ENABLED\`\` bit to reflect its plug status. The kernel will
+then dynamically mark the vCPU as \`\`present\`\` within the OS when the
+\`\`ACPI_STA_DEVICE_ENABLED\`\` bit becomes set during hot-add. Changes to the
+firmware policy can be notified to the OS via device-check or eject-request.
 
 CPUs described as \`\`enabled\`\` in the static table, should not have their _STA
 modified dynamically by firmware. Soft-restart features such as kexec will
diff --git a/arch/arm64/kernel/acpi.c b/arch/arm64/kernel/acpi.c
index 5891f92c2035..681aa2bbc399 100644
--- a/arch/arm64/kernel/acpi.c
+++ b/arch/arm64/kernel/acpi.c
@@ -448,12 +448,14 @@ int acpi_map_cpu(acpi_handle handle, phys_cpuid_t physid, u32 apci_id,
         return *pcpu;
     }
 
+    set_cpu_present(*pcpu, true);
     return 0;
 }
 EXPORT_SYMBOL(acpi_map_cpu);
 
 int acpi_unmap_cpu(int cpu)
 {
+    set_cpu_present(cpu, false);
     return 0;
 }
 EXPORT_SYMBOL(acpi_unmap_cpu);
diff --git a/arch/arm64/kernel/smp.c b/arch/arm64/kernel/smp.c
index 543d3459f6e3..24f8448e1fbb 100644
--- a/arch/arm64/kernel/smp.c
+++ b/arch/arm64/kernel/smp.c
@@ -556,6 +556,11 @@ struct acpi_madt_generic_interrupt *acpi_cpu_get_madt_gicc(int cpu)
 }
 EXPORT_SYMBOL_GPL(acpi_cpu_get_madt_gicc);
 
+static bool acpi_cpu_is_present(int cpu)
+{
+    return acpi_cpu_get_madt_gicc(cpu)->flags & ACPI_MADT_ENABLED;
+}
+
 /*
  * acpi_map_gic_cpu_interface - parse processor MADT entry
  *
@@ -660,6 +665,10 @@ static void __init acpi_parse_and_init_cpus(void)
         early_map_cpu_to_node(i, acpi_numa_get_nid(i));
 }
 #else
+static bool acpi_cpu_is_present(int cpu)
+{
+    return false;
+}
 #define acpi_parse_and_init_cpus(...)    do { } while (0)
 #endif
 
@@ -798,7 +807,8 @@ void __init smp_prepare_cpus(unsigned int max_cpus)
         if (err)
             continue;
 
-        set_cpu_present(cpu, true);
+        if (acpi_disabled || acpi_cpu_is_present(cpu))
+            set_cpu_present(cpu, true);
         numa_store_cpu_info(cpu);
     }
 }
-- 
2.34.1
```

---

```
next prev parent reply    other threads:[~2026-06-10  7:52 UTC|newest]

Thread overview: 5+ messages / expand[flat|nested]  mbox.gz  Atom feed  top
2026-06-10  7:52 [PATCH v4 0/2] arm64: acpi: Fix NULL kobject warning in cpuhp_smt_enable() Jinjie Ruan
2026-06-10  7:52 \` [PATCH v4 1/2] arm64: smp: Fix hot-unplug tearing by forcing unregistration Jinjie Ruan
2026-06-10 11:38   \` Catalin Marinas
2026-06-10  7:52 \` Jinjie Ruan [this message]
2026-06-10 12:43   \` [PATCH v4 2/2] cpu/hotplug: Fix NULL kobject warning in cpuhp_smt_enable() Catalin Marinas
```

---

```
Reply instructions:

You may reply publicly to this message via plain-text email
using any one of the following methods:

* Save the following mbox file, import it into your mail client,
  and reply-to-all from there: mbox

  Avoid top-posting and favor interleaved quoting:
  https://en.wikipedia.org/wiki/Posting_style#Interleaved_style

* Reply using the --to, --cc, and --in-reply-to
  switches of git-send-email(1):

  git send-email \
    --in-reply-to=20260610075202.3597031-3-ruanjinjie@huawei.com \
    --to=ruanjinjie@huawei.com \
    --cc=arnd@arndb.de \
    --cc=catalin.marinas@arm.com \
    --cc=chenl311@chinatelecom.cn \
    --cc=corbet@lwn.net \
    --cc=dietmar.eggemann@arm.com \
    --cc=fengchengwen@huawei.com \
    --cc=gshan@redhat.com \
    --cc=jic23@kernel.org \
    --cc=linux-arm-kernel@lists.infradead.org \
    --cc=linux-doc@vger.kernel.org \
    --cc=linux-kernel@vger.kernel.org \
    --cc=lpieralisi@kernel.org \
    --cc=maz@kernel.org \
    --cc=mrigendra.chaubey@gmail.com \
    --cc=pierre.gondois@arm.com \
    --cc=punit.agrawal@oss.qualcomm.com \
    --cc=skhan@linuxfoundation.org \
    --cc=sudeep.holla@kernel.org \
    --cc=suzuki.poulose@arm.com \
    --cc=timothy.hayes@arm.com \
    --cc=will@kernel.org \
    /path/to/YOUR_REPLY

  https://kernel.org/pub/software/scm/git/docs/git-send-email.html

* If your mail client supports setting the In-Reply-To header
  via mailto: links, try the mailto: link
```
Be sure your reply has a **Subject:** header at the top and a blank line before the message body.

---

```
This is a public inbox, see mirroring instructions
for how to clone and mirror all data and code used for this inbox;
as well as URLs for NNTP newsgroup(s).
```