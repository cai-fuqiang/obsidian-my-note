---
type: literature
status: processed
category: intel_spec
summary: pause 在Guest中的行为受两个字段控制 pause exiting 和pause-loop exiting(ple)。其中ple是为了优化Guest kernel执行spinlock，避免执行pause 频繁vm-exit。于是其增加了一个机制，只有在某个设置的时间窗口内，pause的执行次数超过了配置的最大次数，才vm-exit.
created: 2026-09-07T20:43:42+08:00
modified: 2026-09-10T15:08:59+08:00
QA:
  - 什么是PLE，intel spec中如何描述的
share_link: https://share.note.sx/wv3mz19t#uN7+o/xfS8f2S3ioIWVnOA
share_updated: 2026-09-10T15:08:56+08:00
---
# summary

> [!summary]
> `= this.summary`

# 引用

pause 行为由 [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3964&selection=144,80,145,19|📖两个字段控制]]
* pause exiting
* pause loop-exiting(ple)

而 pause-loop exiting [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3965&selection=40,0,40,67|📖 只能在 CPL == 0 的情况下使用]]

首先说 `CPL >= 0`, **pause ==只受 pause exiting== 控制**:
* 0: 正常执行
* 1:  pause 每次执行都vm-exit

***

而 `CPU ==0` 时:
* `pause exiting == 1` : pause 每次执行都vm-exit
* `pause exiting ==0 && pause-loop exiting`: 正常执行
* `pause exiting ==0 && pause-loop exiting ==1` : 受 pause-loop 功能的其他配置字段影响
我们来详细看下第三种情况, 该ple功能增加了两个控制字段:
* **ple_gap**
* **ple_window**

> [!summary]  可以简单理解为，如果在`ple_gap`这段时间内，pause 指令执行的次数超过`ple_window` 则触发vm-exit(其中[[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3965&selection=27,1,28,21|📖 ple 的速率和tsc频率相同]])
> > 具体解释可以参考 [[325462-sdm-vol-1-2abcd-3abcd-4.pdf#page=3965&selection=20,0,26,43|📖原文]]


# 适用边界
* 本文仅描述intel spec中 ple的相关细节，并不包括PAUSE指令本身的作用
* 本文不包含OS侧的实现
# related

## 可提炼的永久笔记
- [ ] 
## 其他引用笔记

# TODO
*  [ ] pause指令解析
*  [ ]  🔽 TSC频率由什么决定
*  [ ] KVM related code of PLE