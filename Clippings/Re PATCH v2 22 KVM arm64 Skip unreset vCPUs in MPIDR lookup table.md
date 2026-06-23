---
title: "Re: [PATCH v2 2/2] KVM: arm64: Skip unreset vCPUs in MPIDR lookup table"
source: "https://lore.kernel.org/all/87o6hd8oc7.wl-maz@kernel.org/"
author:
published:
created: 2026-06-15
description:
tags:
  - "clippings"
---
```
From: Marc Zyngier <maz@kernel.org>
To: fuqiang wang <fuqiang.wng@gmail.com>
Cc: Oliver Upton <oupton@kernel.org>,
    Zenghui Yu <yuzenghui@huawei.com>,
    linux-kernel@vger.kernel.org, kvmarm@lists.linux.dev,
    dongxu zhang <xu910121@sina.com>,
    wangfuqiang49 <wangfuqiang49@jd.com>
Subject: Re: [PATCH v2 2/2] KVM: arm64: Skip unreset vCPUs in MPIDR lookup table
Date: Sun, 14 Jun 2026 10:26:32 +0100    [thread overview]
Message-ID: <87o6hd8oc7.wl-maz@kernel.org> (raw)
In-Reply-To: <20260611144042.97981-3-fuqiang.wng@gmail.com>

On Thu, 11 Jun 2026 15:40:42 +0100,
fuqiang wang <fuqiang.wng@gmail.com> wrote:
> 
> When a VM is created with CPU hotplug support,

I'm not sure what you mean by "hotplug support". KVM has no support
for vcpu hotplug at all (all vcpus must have been created before the
VM can run).

> kvm_for_each_vcpu() can
> walk vCPUs that have not been reset yet. Their MPIDR_EL1 state is still
> zero, which aliases vCPU0 when populating the compressed MPIDR lookup
> table.
> 
> As a result, cmpidr_to_idx[0] can be overwritten with the index of an
> unreset vCPU. A lookup for MPIDR 0 then returns the wrong vCPU, which
> can prevent interrupts targeting vCPU0 from being delivered correctly
> and make guest boot extremely slow.

OK, so the problem you are describing is related to vcpus that have
haven't gone through the INIT phase, and really has nothing to do with
hotplug.

> 
> Skip vCPUs whose MPIDR_EL1 value does not have the RES1 bit set.
> 
> Fixes: 5544750efd51 ("KVM: arm64: Build MPIDR to vcpu index cache at runtime")
> Signed-off-by: fuqiang wang <fuqiang.wng@gmail.com>
> ---
>  arch/arm64/include/asm/kvm_emulate.h |  9 +++++++++
>  arch/arm64/kvm/arm.c                 | 14 ++++++++++++--
>  2 files changed, 21 insertions(+), 2 deletions(-)
> 
> diff --git a/arch/arm64/include/asm/kvm_emulate.h b/arch/arm64/include/asm/kvm_emulate.h
> index 5bf3d7e1d92c..3d2f0a8b040d 100644
> --- a/arch/arm64/include/asm/kvm_emulate.h
> +++ b/arch/arm64/include/asm/kvm_emulate.h
> @@ -506,6 +506,15 @@ static inline unsigned long kvm_vcpu_get_mpidr_aff(struct kvm_vcpu *vcpu)
>      return __vcpu_sys_reg(vcpu, MPIDR_EL1) & MPIDR_HWID_BITMASK;
>  }
>  
> +/*
> + * Check if vCPU MPIDR_EL1 has been reset. MPIDR_EL1.bit[31] is RES1
> + * and set during reset; a zero value indicates the vCPU is unreset.
> + */
> +static inline bool kvm_vcpu_mpidr_is_reset(struct kvm_vcpu *vcpu)
> +{
> +    return !!(__vcpu_sys_reg(vcpu, MPIDR_EL1) & MPIDR_RES1_BITMASK);
> +}
> +

This helper has only a single caller, so it would better be placed in
the function that makes use of it, specially considering that its a
one-liner.

>  static inline void kvm_vcpu_set_be(struct kvm_vcpu *vcpu)
>  {
>      if (vcpu_mode_is_32bit(vcpu)) {
> diff --git a/arch/arm64/kvm/arm.c b/arch/arm64/kvm/arm.c
> index 3732ee9eb0d4..fccfa97370df 100644
> --- a/arch/arm64/kvm/arm.c
> +++ b/arch/arm64/kvm/arm.c
> @@ -887,8 +887,18 @@ static void kvm_init_mpidr_data(struct kvm *kvm)
>      data->mpidr_mask = mask;
>  
>      kvm_for_each_vcpu(c, vcpu, kvm) {
> -        u64 aff = kvm_vcpu_get_mpidr_aff(vcpu);
> -        u16 index = kvm_mpidr_index(data, aff);
> +        u64 aff;
> +        u16 index;
> +
> +        /*
> +         * Skip vCPUs that haven't been reset yet; their MPIDR_EL1 is
> +         * zero.
> +         */
> +        if (!kvm_vcpu_mpidr_is_reset(vcpu))
> +            continue;

But what about the initial loop that computes the significant bits
amongst the vcpus?

> +
> +        aff = kvm_vcpu_get_mpidr_aff(vcpu);
> +        index = kvm_mpidr_index(data, aff);

In all honesty, I think this is a userspace bug more than anything
else, and checking for random bits in MPDR_EL1 to verify whether the
value is plausible is gross.

Yhis isn't different from setting MPIDR_EL1 to the same value on all
vcpus, which we don't try to mitigate. Late setting of MPIDR_EL1 also
defeats the whole point of having a cache for the affinity to index
conversion, making SGIs pretty slow for late CPUs.

I really think that by not finalising your vcpus and start running the
guest, you have cornered yourself pretty badly, and we shouldn't try
to paper over it.

Thanks,

    M.

-- 
Jazz isn't dead. It just smells funny.
```

---

```
prev parent reply    other threads:[~2026-06-14  9:23 UTC|newest]

Thread overview: 4+ messages / expand[flat|nested]  mbox.gz  Atom feed  top
2026-06-11 14:40 [PATCH v2 0/2] KVM: arm64: Fix MPIDR lookup for unreset vCPUs fuqiang wang
2026-06-11 14:40 \` [PATCH v2 1/2] arm64: Add MPIDR_EL1 RES1 definitions fuqiang wang
2026-06-11 14:40 \` [PATCH v2 2/2] KVM: arm64: Skip unreset vCPUs in MPIDR lookup table fuqiang wang
2026-06-14  9:26   \` Marc Zyngier [this message]
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
    --in-reply-to=87o6hd8oc7.wl-maz@kernel.org \
    --to=maz@kernel.org \
    --cc=fuqiang.wng@gmail.com \
    --cc=kvmarm@lists.linux.dev \
    --cc=linux-kernel@vger.kernel.org \
    --cc=oupton@kernel.org \
    --cc=wangfuqiang49@jd.com \
    --cc=xu910121@sina.com \
    --cc=yuzenghui@huawei.com \
    /path/to/YOUR_REPLY

  https://kernel.org/pub/software/scm/git/docs/git-send-email.html

* If your mail client supports setting the In-Reply-To header
  via mailto: links, try the mailto: link
```
Be sure your reply has a **Subject:** header at the top and a blank line before the message body.

---

```
This is an external index of several public inboxes,
see mirroring instructions on how to clone and mirror
all data and code used by this external index.
```