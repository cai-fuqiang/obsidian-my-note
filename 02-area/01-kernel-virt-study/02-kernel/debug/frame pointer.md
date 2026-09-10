# 测试

代码如下:
```cpp
#include <stdio.h>

void foo1()
{
        char b[16];
}
void foo()
{
        char a[16];
        foo1();

}
int main()
{
        foo();
}
```

使用下面编译选项编译:
```
gcc -S main.c -o main.S -O0
```

输出汇编代码如下：
```
	.file	"main.c"
	.text
	.globl	foo1
	.type	foo1, @function
foo1:
.LFB0:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	nop
	popq	%rbp
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE0:
	.size	foo1, .-foo1
	.globl	foo
	.type	foo, @function
foo:
.LFB1:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$16, %rsp
	movl	$0, %eax
	call	foo1
	nop
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE1:
	.size	foo, .-foo
	.globl	main
	.type	main, @function
main:
.LFB2:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	movl	$0, %eax
	call	foo
	movl	$0, %eax
	popq	%rbp
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE2:
	.size	main, .-main
	.ident	"GCC: (GNU) 12.3.1 (openEuler 12.3.1-30.oe2403)"
	.section	.note.GNU-stack,"",@progbits
```

main->foo->foo1堆栈如下:

![[frame_point_example.excalidraw|800]]