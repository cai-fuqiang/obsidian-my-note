---
share_link: https://share.note.sx/qoigcyvz#kQOdPC1dkln6dIPl6E8gyw
share_updated: 2026-09-01T11:19:27+08:00
modified: 2026-09-17T10:52:10+08:00
---

| test_item                                              | null_io      | stat   | open       | select | sig_install | sig_handle | fork      | exec      | shell      |
| :----------------------------------------------------- | :----------- | :----- | :--------- | :----- | :---------- | :--------- | :-------- | :-------- | :--------- |
| bare-1                                                 | 0.187        | 0.731  | 1.126      | 4.804  | 0.187       | 0.799      | 309.731   | 444.895   | 1386.726   |
| <mark style="background:#fdbfff">kvm-on-bare-1         | 0.1</mark>54 | 0.481  | 1.232      | 6.213  | 0.247       | 1.787      | 682.947   | 696.164   | 1828.938   |
| <mark style="background:#b1ffff">kvm-on-kvm-1          | 0.</mark>111 | 0.463  | 0.731      | 5.023  | 0.12        | 0.759      | 583.927   | 1003.918  | 2227.929   |
| ==pvm-on-kvm-1==                                       | 0.343        | 0.677  | 1.149      | 5.194  | 0.328       | 0.988      | 2022.125  | 2573.153  | 5883.102   |
| bare-32                                                | 3.133        | 8.766  | 15.809     | 6.64   | 0.392       | 2.389      | 650.856   | 981.168   | 2536.703   |
| <mark style="background:#fdbfff">kvm-on-bare-32</mark> | 4.022        | 9.011  | 14.61      | 11.7   | 0.426       | 3.865      | 1734.415  | 1681.543  | 3754.455   |
| <mark style="background:#b1ffff">kvm-on-kvm-32</mark>  | 2.365        | 6.515  | 14.501     | 7.317  | 0.221       | 2.801      | 1245.33   | 1795.778  | 3765.128   |
| ==pvm-on-kvm-32==                                      | 2.434        | 13.214 | ==13.905== | 7.483  | 0.438       | ==2.561==  | 50653.639 | 68659.371 | 150289.469 |

| test_item   | file_0k_create | file_0k_delete | file_10k | file_10k | mmap  | prot_fault | page_fault | select_100fd |
| :---------- | :------------- | :------------- | :------- | :------- | :---- | :--------- | :--------- | :----------- |
| bare        | 8.277          | 6.546          | 15.346   | 9.871    | 56.0  | 0.487      | 0.2        | 1.051        |
| kvm-on-kvm  | 2.572          | 2.322          | 8.851    | 3.851    | 55.0  | 0.512      | 0.226      | 1.062        |
| kvm-on-bare | 2.522          | 2.292          | 7.94     | 4.36     | 60.0  | 0.542      | 0.264      | 1.085        |
| pvm-on-kvm  | 3.044          | 2.442          | 8.42     | 4.099    | 379.0 | 2.727      | 1.283      | 1.28         |

## 补测 3轮

| test_item                                             | null_io  | stat      | open                                           | select                                        | sig_install                            | sig_handle | fork                                              | exec                                              | shell                                              |
| :---------------------------------------------------- | :------- | :-------- | :--------------------------------------------- | :-------------------------------------------- | :------------------------------------- | :--------- | :------------------------------------------------ | :------------------------------------------------ | :------------------------------------------------- |
| pvm-on-bare-1                                         | 0.337    | 0.666     | 1.141                                          | 5.287                                         | 0.327                                  | 0.961      | 1420.185                                          | 2001.834                                          | 4444.357                                           |
| kvm-on-kvm-1                                          | 0.111    | 0.461     | 0.737                                          | 5.12                                          | 0.12                                   | 0.765      | 586.278                                           | 1010.091                                          | 2105.318                                           |
| kvm-on-bare-1                                         | 0.151    | 0.47      | 0.832                                          | 5.062                                         | 0.167                                  | 0.905      | 541.919                                           | 719.883                                           | 1602.148                                           |
| pvm-on-kvm-1                                          | 0.336    | 0.677     | 1.154                                          | 5.203                                         | 0.333                                  | 0.987      | 2026.735                                          | 2648.457                                          | 5769.492                                           |
| pvm-on-bare-32                                        | 2.335    | 6.08      | 13.395                                         | 7.242                                         | 0.434                                  | 2.389      | 33034.993                                         | 46777.713                                         | 99204.509                                          |
| <mark style="background:#b1ffff">kvm-on-bare-32       | 3.118    | 6.152     | 13.524                                         | 7.353                                         | 0.317                                  | 2.482      | 923.95                                            | 1220.742                                          | 2657.276                                           |
| <mark style="background:#d3f8b6">kvm-on-kvm-32</mark> | 3.214    | 6.4       | 14.123                                         | 7.345                                         | 0.222                                  | 2.71       | 1247.406                                          | 1790.908                                          | 3510.976                                           |
| ==pvm-on-kvm-32==                                     | ==2.99== | ==6.332== | <mark style="background:#d3f8b6">14.196</mark> | <mark style="background:#d3f8b6">7.511</mark> | <mark style="background:#d3f8b6">0.442 | ==2.533==  | <mark style="background:#fdbfff">48918.674</mark> | <mark style="background:#fdbfff">67820.397</mark> | <mark style="background:#fdbfff">136911.634</mark> |

> [!bug] PVM 的性能跟论文中不完全贴合.前5个测试项目，论文中有一次PVM落后，而这里有三次

| test_item   | file_0k_create | file_0k_delete | file_10k | file_10k | mmap    | prot_fault | page_fault | select_100fd |
| :---------- | :------------- | :------------- | :------- | :------- | :------ | :--------- | :--------- | :----------- |
| pvm-on-bare | 2.909          | 2.532          | 8.529    | 3.915    | 261.0   | 1.648      | 0.98       | 1.263        |
| kvm-on-kvm  | 2.551          | 2.25           | 7.704    | 3.852    | 53.667  | 0.514      | 0.224      | 1.06         |
| kvm-on-bare | 2.551          | 2.281          | 7.666    | 4.119    | 61.0    | 0.582      | 0.256      | 1.109        |
| pvm-on-kvm  | 3.031          | 2.484          | 8.273    | 4.157    | 402.667 | 2.936      | 1.297      | 1.296        |


# ubuntu

| test_item                                             | null_io   | stat      | open_close | select_tcp                                    | sig_install                                   | sig_handle | fork_proc | exec_proc  | shell_proc |
| :---------------------------------------------------- | :-------- | :-------- | :--------- | :-------------------------------------------- | :-------------------------------------------- | :--------- | :-------- | :--------- | :--------- |
| kvm-on-bare-1                                         | 0.114     | 0.488     | 1.073      | 2.611                                         | 0.13                                          | 0.947      | 509.765   | 1462.2     | 2137.617   |
| kvm-on-kvm-1                                          | 0.112     | 0.462     | 0.736      | 5.045                                         | 0.12                                          | 0.761      | 582.601   | 2498.461   | 3572.178   |
| kvm-on-bare-32                                        | 2.8       | 6.29      | 14.364     | 4.909                                         | 0.234                                         | 2.762      | 873.104   | 2624.517   | 3770.646   |
| <mark style="background:#d3f8b6">kvm-on-kvm-32</mark> | 2.64      | 6.339     | 13.943     | 7.298                                         | 0.221                                         | 2.689      | 1255.852  | 4412.984   | 6141.244   |
| ==pvm-on-kvm-32==                                     | ==2.389== | ==6.176== | ==13.734== | <mark style="background:#d3f8b6">7.498</mark> | <mark style="background:#d3f8b6">0.439</mark> | ==2.601==  | 50006.33  | 128668.074 | 193721.949 |

^00c9d5

使用ubuntu 镜像测试减少为两次。

| test_item   | file_0k_create | file_0k_delete | file_10k_create | file_10k_delete | mmap_usec | prot_fault | page_fault | select_100fd |
| :---------- | :------------- | :------------- | :-------------- | :-------------- | :-------- | :--------- | :--------- | :----------- |
| kvm-on-bare | 13.46          | 13.325         | 23.425          | 17.34           | 75.0      | 0.534      | 0.268      | 0.979        |
| kvm-on-kvm  | 2.562          | 2.341          | 7.645           | 3.973           | 55.0      | 0.503      | 0.225      | 1.065        |
| pvm-on-kvm  | 3.045          | 2.553          | 8.249           | 4.158           | 347.667   | 2.519      | 1.296      | 1.277        |

<!--
* pvm-on-kvm
```
 /Users/wangfuqiang49/workspace/test-units/reports/run-lmbench-process-table-test_w_vm_nest_u-parallelism-1__plus_2-20260901-181523/summary_by_test.csv
```

* kvm-on-bare

```
 /Users/wangfuqiang49/workspace/test-units/reports/run-lmbench-process-table-test_w_vm_u-parallelism-1__plus_2-20260901-182848/summary_by_test.csv
```

* kvm-on-kvm
```
Summary CSV:      /Users/wangfuqiang49/workspace/test-units/reports/run-lmbench-process-table-test_w_vm_nest_u-parallelism-1__plus_2-20260901-184314/summary_by_test.csv
```
-->
# 附录
## ubuntu其他

| test_item                                        | pagefault_usec_avg |
| :----------------------------------------------- | :----------------- |
| lmbench-lat-pagefault-kvm-on-bare-parallelism-1  | 0.266              |
| lmbench-lat-pagefault-kvm-on-bare-parallelism-2  | 0.278              |
| lmbench-lat-pagefault-kvm-on-bare-parallelism-4  | 0.284              |
| lmbench-lat-pagefault-kvm-on-bare-parallelism-8  | 0.294              |
| lmbench-lat-pagefault-kvm-on-bare-parallelism-16 | 0.302              |
| lmbench-lat-pagefault-kvm-on-kvm-parallelism-1   | 0.274              |
| lmbench-lat-pagefault-kvm-on-kvm-parallelism-2   | 0.363              |
| lmbench-lat-pagefault-kvm-on-kvm-parallelism-4   | 0.425              |
| lmbench-lat-pagefault-kvm-on-kvm-parallelism-8   | 0.453              |
| lmbench-lat-pagefault-kvm-on-kvm-parallelism-16  | 0.461              |
| lmbench-lat-pagefault-pvm-on-kvm-parallelism-1   | 1.25               |
| lmbench-lat-pagefault-pvm-on-kvm-parallelism-2   | 2.036              |
| lmbench-lat-pagefault-pvm-on-kvm-parallelism-4   | 2.96               |
| lmbench-lat-pagefault-pvm-on-kvm-parallelism-8   | 5.533              |
| lmbench-lat-pagefault-pvm-on-kvm-parallelism-16  | 38.12              |

| test_item                                   | mapped_mib_avg | mmap_usec_avg |
| :------------------------------------------ | :------------- | :------------ |
| lmbench-lat-mmap-kvm-on-bare-parallelism-1  | 8.389          | 74.0          |
| lmbench-lat-mmap-kvm-on-bare-parallelism-2  | 8.389          | 106.333       |
| lmbench-lat-mmap-kvm-on-bare-parallelism-4  | 8.389          | 150.0         |
| lmbench-lat-mmap-kvm-on-bare-parallelism-8  | 8.389          | 344.667       |
| lmbench-lat-mmap-kvm-on-bare-parallelism-16 | 8.389          | 2846.5        |
| lmbench-lat-mmap-kvm-on-kvm-parallelism-1   | 8.389          | 65.0          |
| lmbench-lat-mmap-kvm-on-kvm-parallelism-2   | 8.389          | 71.0          |
| lmbench-lat-mmap-kvm-on-kvm-parallelism-4   | 8.389          | 85.0          |
| lmbench-lat-mmap-kvm-on-kvm-parallelism-8   | 8.389          | 107.333       |
| lmbench-lat-mmap-kvm-on-kvm-parallelism-16  | 8.389          | 186.667       |
| lmbench-lat-mmap-pvm-on-kvm-parallelism-1   | 8.389          | 1782.0        |
| lmbench-lat-mmap-pvm-on-kvm-parallelism-2   | 8.389          | 395.0         |
| lmbench-lat-mmap-pvm-on-kvm-parallelism-4   | 8.389          | 499.0         |
| lmbench-lat-mmap-pvm-on-kvm-parallelism-8   | 8.389          | 779.333       |
| lmbench-lat-mmap-pvm-on-kvm-parallelism-16  | 8.389          | 2061.0        |

| test_item                                              | transfer_mb_avg | bandwidth_mb_per_sec_avg |
| :----------------------------------------------------- | :-------------- | :----------------------- |
| lmbench-bw-mem-kvm-on-bare-operation-rd-parallelism-1  | 8.39            | 32722.303                |
| lmbench-bw-mem-kvm-on-bare-operation-rd-parallelism-2  | 8.39            | 64544.04                 |
| lmbench-bw-mem-kvm-on-bare-operation-rd-parallelism-4  | 8.39            | 127035.687               |
| lmbench-bw-mem-kvm-on-bare-operation-rd-parallelism-8  | 8.39            | 59375.99                 |
| lmbench-bw-mem-kvm-on-bare-operation-rd-parallelism-16 |                 |                          |
| lmbench-bw-mem-kvm-on-kvm-operation-rd-parallelism-2   | 8.39            | 62631.243                |
| lmbench-bw-mem-kvm-on-kvm-operation-rd-parallelism-4   | 8.39            | 119023.01                |
| lmbench-bw-mem-kvm-on-kvm-operation-rd-parallelism-8   | 8.39            | 65832.417                |
| lmbench-bw-mem-kvm-on-kvm-operation-rd-parallelism-16  | 8.39            | 70283.263                |
| lmbench-bw-mem-kvm-on-kvm-operation-rd-parallelism-1   | 8.39            | 31372.16                 |
| lmbench-bw-mem-pvm-on-kvm-operation-rd-parallelism-1   | 8.39            | 31001.61                 |
| lmbench-bw-mem-pvm-on-kvm-operation-rd-parallelism-2   | 8.39            | 62064.147                |
| lmbench-bw-mem-pvm-on-kvm-operation-rd-parallelism-8   | 8.39            | 61936.457                |
| lmbench-bw-mem-pvm-on-kvm-operation-rd-parallelism-4   | 8.39            | 93385.053                |
| lmbench-bw-mem-pvm-on-kvm-operation-rd-parallelism-16  | 8.39            | 64671.18                 |
| lmbench-bw-mem-kvm-on-bare-operation-wr-parallelism-1  | 8.39            | 21200.84                 |
| lmbench-bw-mem-kvm-on-bare-operation-wr-parallelism-2  | 8.39            | 40607.753                |
| lmbench-bw-mem-kvm-on-bare-operation-wr-parallelism-4  | 8.39            | 52024.577                |
| lmbench-bw-mem-kvm-on-bare-operation-wr-parallelism-8  | 8.39            | 24076.233                |
| lmbench-bw-mem-kvm-on-bare-operation-wr-parallelism-16 | 8.39            | 14206.835                |
| lmbench-bw-mem-kvm-on-kvm-operation-wr-parallelism-1   | 8.39            | 20365.767                |
| lmbench-bw-mem-kvm-on-kvm-operation-wr-parallelism-2   | 8.39            | 40789.133                |
| lmbench-bw-mem-kvm-on-kvm-operation-wr-parallelism-4   | 8.39            | 75026.567                |
| lmbench-bw-mem-kvm-on-kvm-operation-wr-parallelism-8   | 8.39            | 29875.277                |
| lmbench-bw-mem-kvm-on-kvm-operation-wr-parallelism-16  | 8.39            | 12161.445                |
| lmbench-bw-mem-pvm-on-kvm-operation-wr-parallelism-1   | 8.39            | 19883.963                |
| lmbench-bw-mem-pvm-on-kvm-operation-wr-parallelism-2   | 8.39            | 39104.093                |
| lmbench-bw-mem-pvm-on-kvm-operation-wr-parallelism-4   | 8.39            | 43437.503                |
| lmbench-bw-mem-pvm-on-kvm-operation-wr-parallelism-8   | 8.39            | 27227.457                |
| lmbench-bw-mem-pvm-on-kvm-operation-wr-parallelism-16  | 8.39            | 10578.585                |