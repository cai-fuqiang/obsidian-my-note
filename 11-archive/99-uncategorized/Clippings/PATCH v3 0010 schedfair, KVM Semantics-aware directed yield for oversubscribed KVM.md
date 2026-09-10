---
title: "[PATCH v3 00/10] sched/fair, KVM: Semantics-aware directed yield for oversubscribed KVM"
source: https://lore.kernel.org/all/20260612013355.59231-1-kernellwp@gmail.com/
author: liwangpeng
published:
created: 2026-06-12
description:
tags:
  - clippings
---
```
From: Wanpeng Li <kernellwp@gmail.com>
To: Peter Zijlstra <peterz@infradead.org>,
    Ingo Molnar <mingo@redhat.com>,
    Thomas Gleixner <tglx@linutronix.de>,
    Paolo Bonzini <pbonzini@redhat.com>,
    Sean Christopherson <seanjc@google.com>
Cc: K Prateek Nayak <kprateek.nayak@amd.com>,
    Christian Borntraeger <borntraeger@linux.ibm.com>,
    Steven Rostedt <rostedt@goodmis.org>,
    Vincent Guittot <vincent.guittot@linaro.org>,
    Juri Lelli <juri.lelli@redhat.com>,
    linux-kernel@vger.kernel.org, kvm@vger.kernel.org,
    Wanpeng Li <wanpengli@tencent.com>,
    Richie Buturla <richie@linux.ibm.com>
Subject: [PATCH v3 00/10] sched/fair, KVM: Semantics-aware directed yield for oversubscribed KVM
Date: Fri, 12 Jun 2026 09:33:45 +0800    [thread overview]
Message-ID: <20260612013355.59231-1-kernellwp@gmail.com> (raw)

From: Wanpeng Li <wanpengli@tencent.com>

On overcommitted hosts, a spinning vCPU often calls yield_to() to let a
lock holder or IPI receiver run.  The hint can be ineffective for two
independent reasons: the scheduler may fail to select the nominated task,
and KVM may nominate a task that is not the one the spinning vCPU is
waiting for.

This series addresses both sides.  The scheduler side credits bounded
EEVDF lag to the nominated next-buddy so the buddy hint is honored across
the relevant cgroup hierarchy, and forces a local reschedule so the
credited buddy can be selected immediately.  The KVM side tracks recent
unicast fixed IPI sender/receiver pairs and prefers the confirmed receiver
when selecting a directed-yield target.

Problem Statement
-----------------

In overcommitted virtualization scenarios, vCPUs frequently spin on locks
held by other vCPUs that are not currently running, or on IPI responses
from vCPUs that are runnable but not scheduled.  Paravirtual spinlock
support and PLE detect these situations and call yield_to() to let the
other vCPU make progress.

The current implementation has two limitations:

1. Scheduler-side limitation:

   yield_to_task_fair() relies on set_next_buddy() to express a preference
   for the target.  set_next_buddy() nominates the target at every level of
   its cgroup ancestor chain, but pick_eevdf()'s PICK_BUDDY branch only
   returns cfs_rq->next when that entity is already eligible
   (entity_eligible()).  A target that is behind avg_vruntime at any level
   of the chain is skipped, and the hint is dropped at the first ineligible
   group entity.

   Even when the target is eligible, yield_to() does not by itself force
   the caller off the CPU.  An active RUN_TO_PARITY protect_slice() on the
   local yielder can therefore keep pick_eevdf() returning the yielder
   instead of the target.

   The recent forfeit-on-yield work (commits 79104becf42b "sched/fair:
   Forfeit vruntime on yield" and 127b90315ca0 "sched/proxy: Yield the
   donor task") makes the yielder ineligible, but it does not make the
   nominated target eligible when that target is behind avg_vruntime, keep
   PICK_BUDDY from being dropped at the first ineligible group entity, or
   cancel an active RUN_TO_PARITY slice on the yielder.  This series builds
   on that behavior by crediting the target and cancelling slice
   protection, so the nominated entity is the one pick_eevdf() returns.

2. KVM-side limitation:

   kvm_vcpu_on_spin() selects a directed-yield target from coarse
   preempted / preempted-in-kernel state.  It cannot distinguish a vCPU
   spinning on an IPI response from a vCPU spinning on a lock.  When a vCPU
   sends an IPI and spins waiting for the response, the heuristic can boost
   an unrelated vCPU and miss the actual IPI receiver.

These effects lengthen lock hold times and increase spin time,
context-switch overhead and cache pressure in overcommitted environments,
especially for workloads with fine-grained synchronization.

Solution Overview
-----------------

Part 1: Scheduler EEVDF lag credit (patches 1-5)

Rather than penalizing the yielding vCPU, credit the nominated target so
pick_eevdf() honors the buddy hint.

The mechanism is EEVDF-native and cgroup-hierarchy-aware:

- Credit bounded EEVDF lag to the nominated next-buddy so pick_eevdf()'s
  PICK_BUDDY branch returns it.  Walk the same ancestor chain that
  set_next_buddy() nominated and credit each not-yet-eligible level, so the
  hint is not dropped at the first ineligible group entity.

- Credit to a small positive-vlag margin, not merely the vlag = 0
  eligibility boundary, so the target stays eligible across several
  scheduling decisions rather than a single pick.  The margin scales with
  runqueue depth and is clamped to entity_lag()'s legal positive-lag bound,
  preserving EEVDF fairness.

- Handle both the off-tree current entity (shifted in place, carrying any
  vprot window) and a queued (on-tree) entity (repositioned via the
  canonical place_entity()-paired requeue used by requeue_delayed_entity(),
  keeping sum_w_vruntime consistent with entity_key()).

- Force a local reschedule at the end of the credit path: cancel
  RUN_TO_PARITY slice protection along the yielder's sched_entity chain and
  resched_curr() the local CPU.  Only this forced preemption is rate
  limited (once per 6ms per rq) to avoid excessive forced preemption on
  PLE-heavy guests; the lag credit itself runs on every directed yield.

The mechanism is gated by SCHED_FEAT(YIELD_TO_LAG_CREDIT) (default on).
With the feature off, yield_to_task_fair() keeps the existing forfeit-only
behavior.

Part 2: KVM IPI-aware directed yield (patches 6-10)

KVM tracks recent unicast fixed IPI sender/receiver relationships and uses
them to prioritize directed-yield targets.

- Record unicast fixed IPIs from both LAPIC delivery paths, the APIC-map
  fast path and the slow fallback, when exactly one destination vCPU
  accepts the interrupt.

- Use READ_ONCE()/WRITE_ONCE() accessors.  The per-vCPU ipi_context state
  is only a best-effort scheduling hint.

- Age out stale relationships with a recency window (50ms default), and
  clear state on a matching-vector EOI without dropping unrelated pending
  IPI state.

Directed-yield candidate selection uses the following priority order:

  1. A confirmed recent IPI receiver of the spinning vCPU.
  2. The arch-specific pending-interrupt hint
     (kvm_arch_dy_has_pending_interrupt()).
  3. The existing preempted / preempted-in-kernel heuristic.

If the strict IPI-aware pass finds no eligible candidate, an optional
second pass falls back to a relaxed preempted-only search.  The fallback is
controlled by the enable_relaxed_boost module parameter (default on).

Runtime controls:
  * /sys/kernel/debug/sched/features (YIELD_TO_LAG_CREDIT)
  * /sys/module/kvm/parameters/ipi_tracking_enabled
  * /sys/module/kvm/parameters/ipi_window_ns
  * /sys/module/kvm/parameters/enable_relaxed_boost

Host-side deployment model
--------------------------

The series is host-side by design.  It requires no guest ABI, paravirtual
driver, negotiated feature bit, or guest kernel change, so existing guests
benefit without coordination between host and guest software.

That deployment model gives the mechanisms broad coverage.  The scheduler
lag credit applies to every yield_to() the host already receives, including
PLE and paravirtual spinlock paths.  The KVM side observes the actual
unicast-IPI sender/receiver relationship at software LAPIC delivery time,
so it covers spin and IPI waits from spinlocks, RCU, smp_call_function()
and IPI-based wakeups rather than a single paravirtualized operation such
as TLB shootdown.

The host-side approach also composes with existing paravirtualization.  If
a guest provides PV TLB shootdown or PV spinlocks, those interfaces reduce
the amount of spinning that reaches the host; this series handles the
residual yield_to() and IPI waits that remain.  It is runtime gated as
described above and can be enabled or disabled per host.

The scheduler side is independent of APICv, IPI virtualization and the
LAPIC delivery path.  The KVM side depends on software LAPIC delivery: when
IPI/EOI virtualization handles the guest's ICR and EOI writes in hardware,
no sender/receiver relationship is recorded, and candidate selection falls
back to the pending-interrupt and preempted heuristics, plus the relaxed
preempted-only pass added in patch 10.  In that configuration the tracking
state stays empty while the scheduler side remains fully active.

The design separates the consumer of the hint from its source.  Software
IPI tracking supplies the confirmed receiver on hosts where software LAPIC
delivery is observable today; a future guest-cooperative scheduling hint
could populate the same slot without changing the priority-ordered
candidate selection.

Performance Results
-------------------

Test environment: a 16-core x86-64 host, 16 vCPUs per guest.  Host CPU
overcommit is varied by co-locating 2, 3 and 4 guests (120 runs per point),
with APICv disabled so the KVM side observes IPI delivery in software.
Dbench reports throughput and reflects the scheduler-side lag credit; the
PARSEC workloads report end-to-end latency reduction under the full series.

Dbench (filesystem metadata operations), throughput improvement:
  2 VMs:  +6.65%
  3 VMs:  +4.80%
  4 VMs:  +7.59%

PARSEC Dedup, simlarge input (IPI-heavy synchronization), latency
reduction:
  2 VMs:  +8.87%
  3 VMs: +10.29%
  4 VMs: +15.60%

PARSEC VIPS, simlarge input (balanced sync and compute), latency
reduction:
  2 VMs: +10.23%
  3 VMs:  +6.63%
  4 VMs:  +4.50%

Analysis:

- Dedup's gains grow with the VM count: as more runnable vCPUs compete for
  each physical CPU, a directed yield is more likely to land on a vCPU that
  is genuinely preempted while an IPI sender spins, so honoring the
  confirmed receiver matters more.

- Dedup, with its IPI-heavy synchronization, benefits most from the
  IPI-aware directed yield.  Preferring the confirmed IPI receiver over the
  generic preempted-lock-holder heuristic shortens IPI response latency.

- VIPS mixes synchronization and compute, so its gains shrink as the VM
  count rises: at higher overcommit more of each run is spent in compute
  that a directed yield cannot accelerate, leaving less spin time to
  recover.

- Dbench benefits primarily from the scheduler-side lag credit; its lock
  patterns involve more direct lock-holder boosting than IPI spinning.

- No configuration regressed; the mechanisms degrade gracefully as
  contention rises.

The gains stem from three factors:

1. Lock holders receive sustained CPU time to complete critical sections,
   reducing lock hold duration and cascading contention.

2. IPI receivers are scheduled promptly when senders spin, reducing IPI
   response latency and wasted spin cycles.

3. Reduced context switching between lock waiters and holders improves
   cache utilization.

Scope of the scheduler-side benefit
-----------------------------------

The lag credit takes effect only when the yielding vCPU and its target
share a runqueue, i.e. when more runnable vCPUs than pCPUs contend for a
CPU:

- Under CPU overcommit - co-located guests, or a VM whose vCPUs are pooled
  onto fewer pCPUs than it has vCPUs - the waiter and the lock-holder or
  IPI-receiver land on the same rq, and the buddy hint applies.  The
  results here are from this regime, with guests co-located so their vCPUs
  contend for shared pCPUs.

- Without such contention - 1:1 vCPU:pCPU pinning, or a matched vCPU:pCPU
  count with no intra-VM overcommit - there is no eligible buddy to credit,
  so the path is inert and adds no overhead or regression.

Independent s390 testing (directed yield there uses the diag9c hypercall)
shows the same pattern: under intra-VM vCPU pooling the yield-to hypercall
rate falls by more than half with a few percent throughput gain, while 1:1
pinning and matched vCPU:pCPU configurations show no change either way.

Directed yield is a same-runqueue mechanism and cannot help a waiter whose
target is on a different rq; extending it to cross-runqueue cases is left
as future work.

Patch Organization
------------------

Patches 1-5: Scheduler EEVDF lag credit

  Patch 1: Add the eevdf_credit_entity_vlag() primitive and the
           YIELD_TO_LAG_CREDIT feature.  Handles the off-tree current
           entity and has no functional effect on its own.

  Patch 2: Credit to a persistent, queue-depth-scaled positive-vlag
           margin, clamped to entity_lag()'s legal bound.

  Patch 3: Extend the primitive to a queued (on-tree) entity via the
           canonical place_entity()-paired requeue.

  Patch 4: Wire the credit walk into yield_to_task_fair(), crediting each
           level of the nominated ancestor chain.

  Patch 5: Force a local reschedule (cancel RUN_TO_PARITY slice protection
           and resched_curr()) so the credited buddy can be selected.
           Activation patch; rate-limits only the forced preemption.

Patches 6-10: KVM IPI-aware directed yield

  Patch 6: Add per-vCPU IPI tracking infrastructure, module parameters and
           helper functions.  Candidate selection is unchanged.

  Patch 7: Track unicast fixed IPI delivery from both LAPIC paths.

  Patch 8: Clear IPI tracking on a matching-vector EOI.

  Patch 9: Implement IPI-aware directed-yield candidate selection with the
           priority order above.

  Patch 10: Add the relaxed preempted-only fallback as a safety net.

Testing
-------

Workloads tested:

- Dbench (filesystem metadata stress)
- PARSEC benchmarks (Dedup, VIPS)
- Kernel compilation (make -j16 in each VM)

No regressions observed on any configuration.  The mechanisms show neutral
to positive impact across diverse workloads.

Rate-limit policy
-----------------

The scheduler-side forced reschedule is rate-limited to bound the cost of
frequent VM exits.  Under the kvm-full profile, PLE-heavy workloads such as
PARSEC VIPS and Dedup take many PAUSE-loop exits; each exit can drive a
yield_to(), and thus a potential forced preemption.  Forcing a reschedule
on every yield_to() would add needless preemption pressure and cache churn.

The series limits only the forced preemption path
(cancel_protect_slice() plus resched_curr()) to once per 6ms per rq.  The
lag credit itself remains unthrottled, so each directed yield refreshes the
buddy hint.  The fixed 6ms interval is intentionally conservative; an
adaptive limit based on the per-rq yield_to()/PLE-exit rate can be explored
separately.

Changelog:

v2 -> v3:
- Redesign the scheduler side.  v2 applied a bounded vruntime penalty to
  the yielding vCPU (a "debooster"); v3 instead credits bounded EEVDF lag
  to the nominated next-buddy so pick_eevdf()'s PICK_BUDDY branch returns
  it.  Crediting the target is EEVDF-native, composes cleanly with
  RUN_TO_PARITY, and avoids the fairness reasoning required when shifting
  the yielder's vruntime in a cgroup hierarchy.  The redesign also removes
  the bulk of the v2 machinery:
  * Drop the cgroup LCA finder, reverse-pair debouncing, the per-rq
    penalty tracking and the dedicated debugfs sysctl.  The mechanism is
    now gated by SCHED_FEAT(YIELD_TO_LAG_CREDIT).
  * Credit to a queue-depth-scaled positive-vlag margin clamped to
    entity_lag()'s legal bound, keeping the target eligible across several
    picks while preserving EEVDF fairness.
  * Handle the off-tree current entity (in-place shift) and a queued
    on-tree entity (canonical place_entity()-paired requeue) separately,
    so sum_w_vruntime stays consistent with entity_key().
  * Add an explicit forced local reschedule that cancels RUN_TO_PARITY
    slice protection so the credited buddy can be selected; only the
    forced preemption is rate limited (6ms/rq), the lag credit runs on
    every yield.
- KVM side keeps the v2 design; rebased and reorganized into five patches
  (infrastructure, track delivery, clear-on-EOI, candidate selection,
  relaxed fallback).  Tracking now hooks both the APIC-map fast path and
  the slow fallback, and the EOI clear is vector-matched.
- Rebase onto v7.1-rc7.

v1 -> v2:
- Rebase onto v6.19-rc1 (v1 was based on v6.18-rc4).
- Drop the "KVM: Fix last_boosted_vcpu index assignment bug" patch, as
  v6.19-rc1 already contains the fix.
- Scheduler side (the v2 vruntime debooster, since replaced in v3):
  * Apply the deboost before yield_task_fair() to adapt to v6.19's EEVDF
    forfeit behavior (se->vruntime = se->deadline), which would otherwise
    inflate the yielder's vruntime before the penalty was computed.
  * Use rq->donor instead of rq->curr for correct EEVDF donor tracking.
  * Use h_nr_queued instead of nr_queued for accurate hierarchical task
    counting in the penalty cap.
  * Drop the vlag assignment (recalculated on dequeue/enqueue) and the
    update_min_vruntime() call (the yielder is cfs_rq->curr, off-tree), and
    remove the unnecessary gran_floor safeguard.
  * Rename the debugfs knob to vcpu_debooster_enabled.
- KVM IPI tracking: improve module-parameter documentation and add the
  kvm_vcpu_is_ipi_receiver() declaration to x86.h.

Wanpeng Li (10):
  sched/fair: Add EEVDF lag credit primitive for nominated next-buddy
  sched/fair: Credit a persistent, queue-depth-scaled vlag margin
  sched/fair: Credit queued next-buddy via canonical requeue
  sched/fair: Credit nominated next-buddy in yield_to_task_fair()
  sched/fair: Force a local resched on yield_to() so the buddy is picked
  KVM: x86: Add IPI tracking infrastructure for directed yield
  KVM: x86/lapic: Track unicast fixed IPI delivery
  KVM: x86/lapic: Clear IPI tracking on matching-vector EOI
  KVM: Add IPI-aware directed-yield candidate selection
  KVM: Add relaxed preempted-only fallback for directed yield

 arch/x86/include/asm/kvm_host.h |  19 +++
 arch/x86/kvm/lapic.c            | 234 +++++++++++++++++++++++++++++++-
 arch/x86/kvm/x86.c              |   3 +
 arch/x86/kvm/x86.h              |   8 ++
 include/linux/kvm_host.h        |   8 ++
 kernel/sched/fair.c             | 224 +++++++++++++++++++++++++++++-
 kernel/sched/features.h         |   9 ++
 kernel/sched/sched.h            |  10 ++
 virt/kvm/kvm_main.c             |  95 +++++++++++--
 9 files changed, 594 insertions(+), 16 deletions(-)

base-commit: 4549871118cf616eecdd2d939f78e3b9e1dddc48
-- 
2.43.0
```

---

```
next             reply    other threads:[~2026-06-12  1:34 UTC|newest]

Thread overview: 17+ messages / expand[flat|nested]  mbox.gz  Atom feed  top
2026-06-12  1:33 Wanpeng Li [this message]
2026-06-12  1:33 \` [PATCH v3 01/10] sched/fair: Add EEVDF lag credit primitive for nominated next-buddy Wanpeng Li
2026-06-12  1:49   \` sashiko-bot
2026-06-12  1:33 \` [PATCH v3 02/10] sched/fair: Credit a persistent, queue-depth-scaled vlag margin Wanpeng Li
2026-06-12  1:53   \` sashiko-bot
2026-06-12  1:33 \` [PATCH v3 03/10] sched/fair: Credit queued next-buddy via canonical requeue Wanpeng Li
2026-06-12  1:55   \` sashiko-bot
2026-06-12  1:33 \` [PATCH v3 04/10] sched/fair: Credit nominated next-buddy in yield_to_task_fair() Wanpeng Li
2026-06-12  1:54   \` sashiko-bot
2026-06-12  1:33 \` [PATCH v3 05/10] sched/fair: Force a local resched on yield_to() so the buddy is picked Wanpeng Li
2026-06-12  1:50   \` sashiko-bot
2026-06-12  1:33 \` [PATCH v3 06/10] KVM: x86: Add IPI tracking infrastructure for directed yield Wanpeng Li
2026-06-12  1:33 \` [PATCH v3 07/10] KVM: x86/lapic: Track unicast fixed IPI delivery Wanpeng Li
2026-06-12  1:33 \` [PATCH v3 08/10] KVM: x86/lapic: Clear IPI tracking on matching-vector EOI Wanpeng Li
2026-06-12  1:33 \` [PATCH v3 09/10] KVM: Add IPI-aware directed-yield candidate selection Wanpeng Li
2026-06-12  1:48   \` sashiko-bot
2026-06-12  1:33 \` [PATCH v3 10/10] KVM: Add relaxed preempted-only fallback for directed yield Wanpeng Li
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
    --in-reply-to=20260612013355.59231-1-kernellwp@gmail.com \
    --to=kernellwp@gmail.com \
    --cc=borntraeger@linux.ibm.com \
    --cc=juri.lelli@redhat.com \
    --cc=kprateek.nayak@amd.com \
    --cc=kvm@vger.kernel.org \
    --cc=linux-kernel@vger.kernel.org \
    --cc=mingo@redhat.com \
    --cc=pbonzini@redhat.com \
    --cc=peterz@infradead.org \
    --cc=richie@linux.ibm.com \
    --cc=rostedt@goodmis.org \
    --cc=seanjc@google.com \
    --cc=tglx@linutronix.de \
    --cc=vincent.guittot@linaro.org \
    --cc=wanpengli@tencent.com \
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