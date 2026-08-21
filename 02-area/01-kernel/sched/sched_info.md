# struct

| 成员           | 作用             |
| ------------ | -------------- |
| pcount       | 在该cpu上运行了多长时间  |
| run_delay    | 在runq上等待了多长时间  |
| last_arrival | 上次运行在CPU上的结束时间 |
| last_queued  | 上次加入该runq的时间   |

# interface
| interface_name     | 作用                              |
| ------------------ | ------------------------------- |
| sched_info_dequeue | 在出队`dequeue_task()`时调用, 任务主要有两个 |
| sched_info_arrive  | 开始调度到CPU上运行时调用，计算该任务在队列上等待了多长时间 |
| sched_info_enqueue | 在入队`enqueue_task()`调用           |
| sched_info_depart  | 进程退出调度时调用，用来计算进程运行了多长时间。        |
| sched_info_switch  |                                 |

| interface_name     | last_queued | run_delay | last_arrival | p_count |
| ------------------ | ----------- | --------- | ------------ | ------- |
| sched_info_dequeue | 0           | + delta   | N/A          | N/A     |
| sched_info_enqueue | rq_lock(rq) | N/A       | N/A          |         |


```ad-note
title: `sched_info_depart()`可能再次调用 `sched_info_enqueue()`
另外, 如果任务还是RUNNING的，sched_info_depart 则再次调用 `sched_info_enqueue`
```


# 附录

## interface注释
### sched_info_dequeue
```
 * We are interested in knowing how long it was from the *first* time a
 * task was queued to the time that it finally hit a CPU, we call this routine
 * from dequeue_task() to account for possible rq->clock skew across CPUs. The
 * delta taken on each CPU would annul the skew.
 
 * 我们关注的是：从任务*首次*入队到它最终被调度到CPU上执行，这之间的时间长度。
 * 我们在 dequeue_task() 中调用此例程，以考虑各CPU之间 rq->clock 可能存在的偏差。
 * 在每个CPU上计算的差值将抵消这种偏差。  
```

### sched_info_arrive
```
 * Called when a task finally hits the CPU.  We can now calculate how
 * long it was waiting to run.  We also note when it began so that we
 * can keep stats on how long its timeslice is.

 * 当任务最终开始运行（命中CPU）时调用。此时我们可以计算它等待运行了多长时间。
 * 同时我们还会记录它开始运行的时间，以便统计其时间片持续时长。
```

### sched_info_enqueue
```
 * This function is only called from enqueue_task(), but also only updates
 * the timestamp if it is already not set.  It's assumed that
 * sched_info_dequeue() will clear that stamp when appropriate.

 * 此函数仅由 enqueue_task() 调用，但仅当时间戳尚未设置时才会更新。
 * 假定 sched_info_dequeue() 会在适当的时候清除该时间戳。
```

### sched_info_depart
```
 * Called when a process ceases being the active-running process involuntarily
 * due, typically, to expiring its time slice (this may also be called when
 * switching to the idle task).  Now we can calculate how long we ran.
 * Also, if the process is still in the TASK_RUNNING state, call
 * sched_info_enqueue() to mark that it has now again started waiting on
 * the runqueue.
   
 * 当进程因非自愿原因（通常是其时间片耗尽）而不再处于活动运行状态时调用
 * （在切换到空闲任务时也可能调用此函数）。此时我们可以计算它运行了多长时间。
 * 同时，如果进程仍处于 TASK_RUNNING 状态，则调用 sched_info_enqueue()
 * 以标记它现在再次开始在运行队列上等待。
```
