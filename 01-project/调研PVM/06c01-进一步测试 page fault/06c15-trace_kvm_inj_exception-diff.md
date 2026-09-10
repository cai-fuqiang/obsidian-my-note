---
created: 2026-09-09T14:46:09+08:00
modified: 2026-09-10T11:03:18+08:00
share_link: https://share.note.sx/jl8oadav#9vOA07RIoG/IHFMIU+q/vQ
share_updated: 2026-09-10T11:03:07+08:00
---
```diff
diff --git a/arch/x86/kvm/trace.h b/arch/x86/kvm/trace.h
index 7ffa05a51feb..70720077974f 100644
--- a/arch/x86/kvm/trace.h
+++ b/arch/x86/kvm/trace.h
@@ -376,14 +376,15 @@ TRACE_EVENT(kvm_inj_virq,
  */
 TRACE_EVENT(kvm_inj_exception,
        TP_PROTO(unsigned exception, bool has_error, unsigned error_code,
-                bool reinjected),
-       TP_ARGS(exception, has_error, error_code, reinjected),
+                bool reinjected, unsigned long cr2),
+       TP_ARGS(exception, has_error, error_code, reinjected, cr2),

        TP_STRUCT__entry(
                __field(        u8,     exception       )
                __field(        u8,     has_error       )
                __field(        u32,    error_code      )
                __field(        bool,   reinjected      )
+               __field(        unsigned long,  cr2)
        ),

        TP_fast_assign(
@@ -391,6 +392,7 @@ TRACE_EVENT(kvm_inj_exception,
                __entry->has_error      = has_error;
                __entry->error_code     = error_code;
                __entry->reinjected     = reinjected;
+               __entry->cr2            = cr2;
        ),

        TP_printk("%s%s%s%s%s",
diff --git a/arch/x86/kvm/x86.c b/arch/x86/kvm/x86.c
index 23c3db7f8286..2a35ded87644 100644
--- a/arch/x86/kvm/x86.c
+++ b/arch/x86/kvm/x86.c
@@ -10244,7 +10244,8 @@ static void kvm_inject_exception(struct kvm_vcpu *vcpu)
        trace_kvm_inj_exception(vcpu->arch.exception.vector,
                                vcpu->arch.exception.has_error_code,
                                vcpu->arch.exception.error_code,
-                               vcpu->arch.exception.injected);
+                               vcpu->arch.exception.injected,
+                               vcpu->arch.cr2);

        vcpu->arch.exception.injected = true;
        kvm_x86_call(inject_exception)(vcpu);

```