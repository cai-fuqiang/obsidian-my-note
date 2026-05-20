
## 封装
![[class-封装]]

我们可以用该`class` new 不同的实例，例如上图中的`xiao wang` 和 `xiao li`。而实例可以初始化不同的 `object`(`instance`)，而这些`object` 又具有相同的操作方法，所以他们共享一套functions。

当然`C` 语言也可以很轻松的抽象出这样的数据结构。（在Linux 内核中大量应用）举例:
```c
struct inode {
		umode_t			i_mode;
	unsigned short		i_opflags;
	...
	const struct inode_operations	*i_op;
	...
};
struct inode_operations {
	struct dentry * (*lookup) (...);
	const char * (*get_link) (...);
	...
};
```

## 继承

继承的作用是让子类可以拥有父类的成员和方法。

![[Excalidraw/class-继承]]
在面向对象语言中使用继承是非常优雅的，可以直接用子类对象调用父类方法

而C语言呢，似乎就没有这么简单，按照之前的程序,  我们需要定义inode的父类，一般的做法是，类似于C++中的组合去做。

```c
struct inode {
	umode_t			i_mode;
	unsigned short		i_opflags;
	...
	const struct inode_operations	*i_op;
};

struct snode {
	struct inode inode;
	int other_data;
	void (*other_func)(void);
};
```

当我们想使用子类的方法时，操作将非常丑陋`snode->inode->i_op->xxx()`
## 多态

![[Excalidraw/class-多态]]

多态则是提供了一种在子类对象定义class时，可以覆盖父类的方法，例如图中的
`what's your name()`function，当我们用父类对象类型调用方法时，则自动调用
子类的方法！
```cpp
class programmer xiaoli = new("xiao li")

//C语言风格haha
class people one_people = (class people )xiaoli;

one_people.what's your name() --> Li God
```