/*
 * hung_resume.c - 内核模块，在 /proc 下创建两个文件:
 *   /proc/hung   - 写入时会将写进程 D 住 (TASK_UNINTERRUPTIBLE)
 *   /proc/resume - 写入时唤醒所有因写 hung 而 D 住的进程
 */

#include <linux/module.h>
#include <linux/proc_fs.h>
#include <linux/uaccess.h>
#include <linux/wait.h>
#include <linux/sched.h>

MODULE_LICENSE("GPL");
MODULE_AUTHOR("wangfuqiang");
MODULE_DESCRIPTION("Proc hung/resume demo: write to /proc/hung blocks, write to /proc/resume wakes all");

static DECLARE_WAIT_QUEUE_HEAD(hung_wq);
static atomic_t do_wake = ATOMIC_INIT(0);

static struct proc_dir_entry *proc_hung;
static struct proc_dir_entry *proc_resume;

/*
 * /proc/hung write handler:
 * 将当前进程设置为 TASK_UNINTERRUPTIBLE 并睡眠在等待队列上，
 * 直到 /proc/resume 被写入时唤醒。
 */
static ssize_t hung_write(struct file *file, const char __user *buf,
			  size_t count, loff_t *ppos)
{
	DEFINE_WAIT(wait);

	pr_info("hung_resume: pid %d (%s) entering D state\n",
		current->pid, current->comm);

	for (;;) {
		prepare_to_wait(&hung_wq, &wait, TASK_UNINTERRUPTIBLE);
		if (atomic_read(&do_wake))
			break;
		schedule();
	}

	finish_wait(&hung_wq, &wait);

	/* 重置唤醒标志（最后一个被唤醒的进程重置） */
	atomic_set(&do_wake, 0);

	pr_info("hung_resume: pid %d (%s) resumed\n",
		current->pid, current->comm);

	return count;
}

/*
 * /proc/resume write handler:
 * 唤醒所有因写 /proc/hung 而 D 住的进程。
 */
static ssize_t resume_write(struct file *file, const char __user *buf,
			    size_t count, loff_t *ppos)
{
	pr_info("hung_resume: waking up all hung processes\n");
	atomic_set(&do_wake, 1);
	wake_up_all(&hung_wq);
	return count;
}

static const struct proc_ops hung_proc_ops = {
	.proc_write = hung_write,
};

static const struct proc_ops resume_proc_ops = {
	.proc_write = resume_write,
};

static int __init hung_resume_init(void)
{
	proc_hung = proc_create("hung", 0222, NULL, &hung_proc_ops);
	if (!proc_hung) {
		pr_err("hung_resume: failed to create /proc/hung\n");
		return -ENOMEM;
	}

	proc_resume = proc_create("resume", 0222, NULL, &resume_proc_ops);
	if (!proc_resume) {
		pr_err("hung_resume: failed to create /proc/resume\n");
		proc_remove(proc_hung);
		return -ENOMEM;
	}

	pr_info("hung_resume: module loaded. /proc/hung and /proc/resume created\n");
	return 0;
}

static void __exit hung_resume_exit(void)
{
	proc_remove(proc_resume);
	proc_remove(proc_hung);

	/* 模块卸载前唤醒所有还在睡眠的进程，避免永久 D 状态 */
	atomic_set(&do_wake, 1);
	wake_up_all(&hung_wq);

	pr_info("hung_resume: module unloaded\n");
}

module_init(hung_resume_init);
module_exit(hung_resume_exit);