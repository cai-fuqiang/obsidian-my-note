---
share_link: https://share.note.sx/hb4kmvsj#aQ8eujtvLZhr8MDLNUdwWw
share_updated: 2026-09-01T11:19:32+08:00
modified: 2026-09-04T15:47:10+08:00
---

# 单虚拟机多线程


## 测试方法

* 每个进程，动态申请1M内存，并以4K粒度访问内存，访问完1M后解除映射。依次循环，直到访问内存大小增长至4G。
* 在每个测试环境中(虚拟机为单实例) 启动`1, 2, 4, 8, 16, 32` 线程进行测试, 所有cpu绑定到一个核心
## 测试结果

![[on-instance-muti-process.svg]]

> [!summary] `pvm-on-xxx` 在单容器多实例下，体现出了不可扩展性


> [!note]- 具体测试数值
> 
> | 测试项                      | 耗时     |
> | :----------------------- | :----- |
> | bare-processes-2         | 1.164  |
> | bare-processes-4         | 1.176  |
> | bare-processes-8         | 1.199  |
> | bare-processes-16        | 1.847  |
> | bare-processes-32        | 3.107  |
> | kvm-on-bare-processes-1  | 1.383  |
> | kvm-on-bare-processes-2  | 1.425  |
> | kvm-on-bare-processes-4  | 1.477  |
> | kvm-on-bare-processes-8  | 1.996  |
> | kvm-on-bare-processes-16 | 3.9    |
> | kvm-on-bare-processes-32 | 9.085  |
> | kvm-on-kvm-processes-1   | 1.225  |
> | kvm-on-kvm-processes-2   | 1.256  |
> | kvm-on-kvm-processes-4   | 1.307  |
> | kvm-on-kvm-processes-8   | 1.596  |
> | kvm-on-kvm-processes-16  | 3.24   |
> | kvm-on-kvm-processes-32  | 7.005  |
> | pvm-on-kvm-processes-1   | 7.004  |
> | pvm-on-kvm-processes-2   | 7.452  |
> | pvm-on-kvm-processes-4   | 8.771  |
> | pvm-on-kvm-processes-8   | 11.482 |
> | pvm-on-kvm-processes-16  | 31.271 |
> | pvm-on-kvm-processes-32  | 73.706 |
> | pvm-on-bare-processes-1  | 4.415  |
> | pvm-on-bare-processes-2  | 4.968  |
> | pvm-on-bare-processes-4  | 5.706  |
> | pvm-on-bare-processes-8  | 10.406 |
> | pvm-on-bare-processes-16 | 20.988 |
> | pvm-on-bare-processes-32 | 57.989 |

# 多虚拟机多线程

## 每次动态申请1M内存

每个实例，动态申请1M内存，并以4K粒度访问内存，访问完1M后解除映射。依次循环，直到访问内存大小增长至1G, 这表示一轮完成，一共做4轮测试。

| test_item               | total  | iteration_1 | iteration_2 | iteration_3 | iteration_4 |
| :---------------------- | :----- | :---------- | :---------- | :---------- | :---------- |
| pvm-on-kvm-instances-16 | 14.906 | 3.9         | 3.987       | 3.579       | 3.438       |
| kvm-on-kvm-instances-16 | 1.49   | 0.394       | 0.365       | 0.364       | 0.368       |
## 每一轮map 1G内存

每个实例，map 1G 内存，并以4K 粒度访问，完成1G后，算是一轮完成，一共做4轮测试。

| test_item                  | total_time | iteration_1 | iteration_2 | iteration_3 | iteration_4 |
| :------------------------- | :--------- | :---------- | :---------- | :---------- | :---------- |
| kvm-on-kvm-instance-16<br> | 5.778      | 3.983       | 0.622       | 0.603       | 0.569       |
| pvm-on-kvm-instance-16     | 16.903     | 5.715       | 4.251       | 3.547       | 3.388       |


