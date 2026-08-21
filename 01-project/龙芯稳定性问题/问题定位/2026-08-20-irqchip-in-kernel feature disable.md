---
data: 2026-08-20
问题分类: patch not merge
是否定位成功: true
目前结论: 当前qemu缺少irqchip in kernel 的部分patch
is_issue: true
instance: --
share_link: https://share.note.sx/eis9awrs#rFzmINj4piWFjpAS9SmRnw
share_updated: 2026-08-20T20:05:39+08:00
---
# 问题现象

香来反馈，在使用了`irqchip in kernel` feature的guest中，会打印下面信息
![[d5c5f4f955ecef8c5e1e15572057d66f.png]]

目前公司的guest并未有上面打印

# 问题定位
经香来提示, qemu 下面代码可能存在问题:
```cpp
int kvm_arch_init(MachineState *ms, KVMState *s)
{
    cap_has_mp_state = kvm_check_extension(s, KVM_CAP_MP_STATE);
    if(!kvm_vm_check_attr(kvm_state, KVM_LOONGARCH_VM_HAVE_IRQCHIP, KVM_LOONGARCH_VM_HAVE_IRQCHIP)) {
        s->kernel_irqchip_allowed = false;
    }

    return 0;
}
```

而host中，并未有`KVM_LOONGARCH_VM_HAVE_IRQCHIP` 的定义.
```cpp
static int kvm_vm_has_attr(struct kvm *kvm, struct kvm_device_attr *attr)
{
	switch (attr->group) {
	case KVM_LOONGARCH_VM_FEAT_CTRL:
		return kvm_vm_feature_has_attr(kvm, attr);
	default:
		return -ENXIO;
	}
}
```

查看openEuler upstream代码，发现有如下patch:
```diff
5b9ece5e96c40f56e7c84bf15d4a5a7d1205bc25
sync header file from upstream

diff --git a/target/loongarch/kvm/kvm.c b/target/loongarch/kvm/kvm.c
index f6e008a517..f724e77a1b 100644
--- a/target/loongarch/kvm/kvm.c
+++ b/target/loongarch/kvm/kvm.c
@@ -973,10 +973,6 @@ int kvm_arch_get_default_type(MachineState *ms)
 int kvm_arch_init(MachineState *ms, KVMState *s)
 {
     cap_has_mp_state = kvm_check_extension(s, KVM_CAP_MP_STATE);
-    if(!kvm_vm_check_attr(kvm_state, KVM_LOONGARCH_VM_HAVE_IRQCHIP, KVM_LOONGARCH_VM_HAVE_IRQCHIP)) {
-        s->kernel_irqchip_allowed = false;
-    }
-
     return 0;
 }
```

* 2026-08-20 20:05:25: 当前代码已经merge部署